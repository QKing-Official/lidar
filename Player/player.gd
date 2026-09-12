extends CharacterBody3D

signal scan_hit(pos: Vector3, is_danger: bool)

# ==================== CONTROLS & SETTINGS ====================
@export var SPEED: float = 5.0
@export var JUMP_VELOCITY: float = 4.5
@export var SCAN_RANGE: float = 60.0

# Wide Circular LiDAR Settings
@export var RAY_COUNT: int = 700
@export var MAX_SPREAD_DEG: float = 48.0
@export var CENTER_WEIGHT: float = 1.4

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var footstep_timer: float = 0.0

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var scanner_ray: RayCast3D = $Head/Camera3D/ScannerRay

func _ready():
	add_to_group("player")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if has_node("/root/SettingsManager"):
		camera.fov = SettingsManager.fov
	_build_crosshair()

	scanner_ray.position = Vector3.ZERO
	scanner_ray.rotation = Vector3.ZERO
	scanner_ray.scale = Vector3.ONE
	scanner_ray.add_exception(self)
	scanner_ray.collide_with_areas = true
	scanner_ray.collide_with_bodies = true
	scanner_ray.collision_mask = 1 | 2

func _build_crosshair():
	var canvas = CanvasLayer.new()
	canvas.name = "CrosshairLayer"
	add_child(canvas)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(center)

	var cross_root = Control.new()
	cross_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(cross_root)

	var horiz = ColorRect.new()
	horiz.color = Color(1.0, 1.0, 1.0, 1.0)
	horiz.size = Vector2(10, 2)
	horiz.position = Vector2(-5, -1)
	horiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cross_root.add_child(horiz)

	var vert = ColorRect.new()
	vert.color = Color(1.0, 1.0, 1.0, 1.0)
	vert.size = Vector2(2, 10)
	vert.position = Vector2(-1, -5)
	vert.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cross_root.add_child(vert)

func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var sens = SettingsManager.mouse_sensitivity if has_node("/root/SettingsManager") else 0.0025
		rotate_y(-event.relative.x * sens)
		head.rotate_x(-event.relative.y * sens)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-80), deg_to_rad(80))

	var clicked = false
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		clicked = true
	elif event.is_action_pressed("fire_lidar"):
		clicked = true

	if clicked:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			if has_node("/root/AudioManager"):
				AudioManager.play_sfx("res://Assets/Audio/click.wav", -5.0, randf_range(1.5, 2.0))
			_fire_circular_scan()
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

var auto_scan: bool = true

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta
		if auto_scan:
			_fire_spherical_scan(100)
	else:
		velocity.y = 0.0
		if auto_scan:
			auto_scan = false

	if Input.is_action_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var move_vec = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")

	var direction = (transform.basis * Vector3(move_vec.x, 0, move_vec.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		
		if is_on_floor():
			footstep_timer += delta
			if footstep_timer >= 0.4:
				footstep_timer = 0.0
				if has_node("/root/AudioManager"):
					AudioManager.play_sfx("res://Assets/Audio/thump.wav", -15.0, randf_range(0.8, 1.2))
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		footstep_timer = 0.0
	
	move_and_slide()
	
	# If the player falls off the ledge in the Finale, instantly respawn them at the entry
	if global_position.y < -10.0 and get_tree().current_scene and get_tree().current_scene.scene_file_path.ends_with("Finale.tscn"):
		global_position = Vector3(17.317, 50.17, 0)
		velocity = Vector3.ZERO

func _fire_circular_scan():
	var max_spread_rad = deg_to_rad(MAX_SPREAD_DEG)
	var vp_size = get_viewport().get_visible_rect().size
	var aspect_ratio = vp_size.x / maxf(vp_size.y, 1.0)

	for i in range(RAY_COUNT):
		var r = pow(randf(), CENTER_WEIGHT)
		var angle = randf_range(0.0, TAU)

		var spread_angle = r * max_spread_rad
		var off_x = cos(angle) * spread_angle * (aspect_ratio * 0.7)
		var off_y = sin(angle) * spread_angle

		var corner_factor = pow(cos(angle), 4.0) + pow(sin(angle), 4.0)
		if r > 0.90 and randf() < corner_factor * 0.5:
			continue

		var dir = Vector3.FORWARD.rotated(Vector3.RIGHT, off_y).rotated(Vector3.UP, -off_x).normalized()

		scanner_ray.target_position = dir * SCAN_RANGE
		scanner_ray.force_raycast_update()

		if scanner_ray.is_colliding():
			var hit_pt = scanner_ray.get_collision_point()
			var collider = scanner_ray.get_collider()

			# Walk up hierarchy to find the enemy instance
			var enemy = null
			var target = collider
			while target != null:
				if target.has_method("add_enemy_dot"):
					enemy = target
					break
				target = target.get_parent()

			# Route cleanly: enemy handles its own dots; world handles everything else
			if enemy:
				enemy.add_enemy_dot(hit_pt)
			else:
				var is_danger = collider.is_in_group("danger") if collider else false
				scan_hit.emit(hit_pt, is_danger)

	scanner_ray.target_position = Vector3(0, 0, -SCAN_RANGE)

func _fire_spherical_scan(rays: int):
	for i in range(rays):
		var dir = Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
		scanner_ray.target_position = dir * SCAN_RANGE
		scanner_ray.force_raycast_update()

		if scanner_ray.is_colliding():
			var hit_pt = scanner_ray.get_collision_point()
			var collider = scanner_ray.get_collider()

			var enemy = null
			var target = collider
			while target != null:
				if target.has_method("add_enemy_dot"):
					enemy = target
					break
				target = target.get_parent()

			if enemy:
				enemy.add_enemy_dot(hit_pt)
			else:
				var is_danger = collider.is_in_group("danger") if collider else false
				scan_hit.emit(hit_pt, is_danger)

	scanner_ray.target_position = Vector3(0, 0, -SCAN_RANGE)

var dead: bool = false

func die(killer: Node3D = null):
	if dead: return
	dead = true
	
	set_physics_process(false)
	
	if killer and killer.scene_file_path:
		if has_node("/root/SaveManager"):
			SaveManager.jumpscare_enemy_scene_file = killer.scene_file_path
			
	get_tree().call_deferred("change_scene_to_file", "res://Menu/Jumpscare.tscn")
