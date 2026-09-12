extends CharacterBody3D

@export var ENEMY_SCALE: float = 1.0
@export var EXPLOSION_RADIUS: float = 6.0
@export var HIDE_MODEL: bool = true
@export var DEBUG_SHOW_MODEL: bool = false

var max_dots: int = 1500
var dot_index: int = 0
var dot_mesh: MultiMeshInstance3D
var dot_timers: PackedFloat32Array
var dot_world_positions: PackedVector3Array
var dot_active: PackedByteArray
var active_dots_count: int = 0

var base_quad_size: float = 0.08
var triggered = false
var explosion_timer = 0.0
var explosion_state = 0 # 0=idle, 1=wait1, 2=flash1, 3=wait2, 4=flash2, 5=explode
var dead = false

func _ready():
	scale = Vector3.ONE * ENEMY_SCALE
	collision_layer = 1
	collision_mask = 1 | 2
	
	if DEBUG_SHOW_MODEL:
		_force_debug_material(self)
	elif HIDE_MODEL:
		_set_model_visibility(self, false)

	_setup_isolated_world_cloud()
	
func _setup_isolated_world_cloud():
	dot_mesh = MultiMeshInstance3D.new()
	dot_mesh.top_level = true
	dot_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	
	var quad = QuadMesh.new()
	quad.size = Vector2(base_quad_size, base_quad_size)
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.vertex_color_use_as_albedo = true
	quad.material = mat
	mm.mesh = quad
	mm.instance_count = max_dots
	dot_mesh.multimesh = mm
	add_child(dot_mesh)
	
	dot_timers.resize(max_dots)
	dot_timers.fill(0.0)
	dot_world_positions.resize(max_dots)
	dot_world_positions.fill(Vector3(0, -9999, 0))
	dot_active.resize(max_dots)
	dot_active.fill(0)
	
	var hidden_t = Transform3D(Basis().scaled(Vector3.ONE * 0.001), Vector3(0, -9999, 0))
	for i in range(max_dots):
		mm.set_instance_transform(i, hidden_t)
		mm.set_instance_color(i, Color(1, 1, 1, 1))

var is_screeching: bool = false

func add_enemy_dot(hit_pos: Vector3):
	print("BoomThing hit at: ", hit_pos)
	if active_dots_count == 0 and not is_screeching:
		is_screeching = true
		if has_node("/root/AudioManager"):
			AudioManager.play_sfx("res://Assets/Audio/static.wav", 0.0, 2.5)
		get_tree().create_timer(1.0).timeout.connect(func(): is_screeching = false)
		
	if not dot_mesh or not dot_mesh.multimesh or dead: return
	
	if not triggered:
		triggered = true
		explosion_state = 1
		explosion_timer = 0.5
	
	_spawn_dot(hit_pos, Color(1,1,1,1) if explosion_state <= 1 else Color(1,0,0,1), 10.0)

func _spawn_dot(pos: Vector3, color: Color, life: float):
	var idx = dot_index
	dot_world_positions[idx] = pos
	dot_timers[idx] = life
	dot_active[idx] = 1
	var t = Transform3D(Basis(), pos)
	dot_mesh.multimesh.set_instance_transform(idx, t)
	dot_mesh.multimesh.set_instance_color(idx, color)
	dot_index = (dot_index + 1) % max_dots

func _physics_process(delta: float):
	_update_individual_dots(delta)
	
	if triggered and not dead:
		explosion_timer -= delta
		if explosion_timer <= 0.0:
			_advance_explosion_state()
			
	if not dead:
		if not is_on_floor():
			velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta
		move_and_slide()

func _advance_explosion_state():
	if explosion_state == 1:
		explosion_state = 2
		_flash_red()
		explosion_timer = 0.2
	elif explosion_state == 2:
		explosion_state = 3
		_clear_dots()
		explosion_timer = 0.2
	elif explosion_state == 3:
		explosion_state = 4
		_flash_red()
		explosion_timer = 0.2
	elif explosion_state == 4:
		explosion_state = 5
		_clear_dots()
		explosion_timer = 0.2
	elif explosion_state == 5:
		_explode()

func _flash_red():
	if has_node("/root/AudioManager"):
		AudioManager.play_sfx("res://Assets/Audio/click.wav", 5.0, 1.5)
	
	for i in range(200):
		var random_pos = global_position + Vector3(randf_range(-1, 1), randf_range(0, 2), randf_range(-1, 1)) * ENEMY_SCALE * 1.5
		_spawn_dot(random_pos, Color(1, 0, 0, 1), 0.5)

func _clear_dots():
	for i in range(max_dots):
		dot_active[i] = 0

func _explode():
	dead = true
	if has_node("/root/AudioManager"):
		AudioManager.play_sfx("res://Assets/Audio/click.wav", 10.0, 0.5)
	
	var player = get_tree().get_first_node_in_group("player")
	if player and is_instance_valid(player):
		if global_position.distance_to(player.global_position) <= EXPLOSION_RADIUS:
			if player.has_method("die"):
				player.die(self)
			else:
				if has_node("/root/SaveManager"):
					SaveManager.reload_current_save()
				else:
					get_tree().reload_current_scene()
	
	_clear_dots()
	
	for i in range(800):
		var dir = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)).normalized()
		_spawn_dot(global_position + dir * randf_range(0.2, EXPLOSION_RADIUS * 1.5), Color(1, 0, 0, 1), randf_range(1.0, 3.0))
	
	collision_layer = 0
	collision_mask = 0
	_set_model_visibility(self, false)
	
	await get_tree().create_timer(4.0).timeout
	queue_free()

func _update_individual_dots(delta: float):
	if not dot_mesh: return
	var mm = dot_mesh.multimesh
	var hidden_t = Transform3D(Basis().scaled(Vector3.ONE * 0.001), Vector3(0, -9999, 0))
	
	var count = 0
	for i in range(max_dots):
		if dot_active[i] == 0:
			mm.set_instance_transform(i, hidden_t)
			continue
			
		dot_timers[i] -= delta
		if dot_timers[i] <= 0.0:
			dot_active[i] = 0
			mm.set_instance_transform(i, hidden_t)
		else:
			count += 1
			mm.set_instance_transform(i, Transform3D(Basis(), dot_world_positions[i]))
			
	active_dots_count = count

func _set_model_visibility(node: Node, is_vis: bool):
	for child in node.get_children():
		if child is MeshInstance3D and child != dot_mesh:
			child.visible = is_vis
		_set_model_visibility(child, is_vis)

func _force_debug_material(node: Node):
	for child in node.get_children():
		if child is MeshInstance3D and child != dot_mesh:
			child.visible = true
			var mat = StandardMaterial3D.new()
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			mat.albedo_color = Color(1.0, 0.0, 1.0)
			child.material_override = mat
		_force_debug_material(child)
