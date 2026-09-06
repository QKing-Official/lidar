extends CharacterBody3D

signal scan_hit(pos: Vector3, is_danger: bool)

# ==================== CONTROLS & SETTINGS ====================
@export var KEY_FORWARD: Key = KEY_W
@export var KEY_BACKWARD: Key = KEY_S
@export var KEY_LEFT: Key = KEY_A
@export var KEY_RIGHT: Key = KEY_D
@export var KEY_JUMP: Key = KEY_SPACE

@export var SPEED: float = 5.0
@export var JUMP_VELOCITY: float = 4.5
@export var MOUSE_SENS: float = 0.0025
@export var SCAN_RANGE: float = 60.0

# Wide Circular LiDAR Settings
@export var RAY_COUNT: int = 700
@export var MAX_SPREAD_DEG: float = 48.0
@export var CENTER_WEIGHT: float = 1.4

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var scanner_ray: RayCast3D = $Head/Camera3D/ScannerRay

func _ready():
	add_to_group("player")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
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
		rotate_y(-event.relative.x * MOUSE_SENS)
		head.rotate_x(-event.relative.y * MOUSE_SENS)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-80), deg_to_rad(80))

	var clicked = false
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		clicked = true
	elif event.is_action_pressed("fire_lidar"):
		clicked = true

	if clicked:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			_fire_circular_scan()
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	if Input.is_key_pressed(KEY_JUMP) and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var move_vec = Vector2.ZERO
	if Input.is_key_pressed(KEY_FORWARD):
		move_vec.y -= 1.0
	if Input.is_key_pressed(KEY_BACKWARD):
		move_vec.y += 1.0
	if Input.is_key_pressed(KEY_LEFT):
		move_vec.x -= 1.0
	if Input.is_key_pressed(KEY_RIGHT):
		move_vec.x += 1.0
	move_vec = move_vec.normalized()

	var direction = (transform.basis * Vector3(move_vec.x, 0, move_vec.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

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

func die():
	get_tree().reload_current_scene()
