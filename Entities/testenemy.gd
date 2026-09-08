extends CharacterBody3D

# ==================== CONFIGURATION ====================
@export_group("Dimensions & Scaling")
@export_range(0.1, 2.0, 0.05) var ENEMY_SCALE: float = 0.5

@export_group("Movement & Speeds")
@export var CHASE_SPEED: float = 1.8
@export var ROTATION_SPEED: float = 5.0
@export var CATCH_DISTANCE: float = 1.8

@export_group("Stealth & Visibility")
@export var HIDE_MODEL: bool = false
@export var DEBUG_SHOW_MODEL: bool = false

@export_group("LiDAR Reaction")
@export var BASE_DOT_LIFETIME: float = 10.0
@export var LIFETIME_JITTER: float = 3.0

var player: CharacterBody3D
var move_direction: Vector3 = Vector3.FORWARD
var active_dots_count: int = 0
var base_quad_size: float = 0.06

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var ledge_ray: RayCast3D
var nav_agent: NavigationAgent3D

# World-Space LiDAR MultiMesh
var dot_mesh: MultiMeshInstance3D
var max_dots: int = 2500
var dot_index: int = 0
var dot_timers: PackedFloat32Array
var dot_max_timers: PackedFloat32Array
var dot_world_positions: PackedVector3Array
var dot_active: PackedByteArray

func _ready():
	# Use Godot's built in node scale to uniformly scale the enemy.
	# Uniform scale is supported by Jolt Physics, unlike non-uniform or child-level scale overrides.
	scale = Vector3.ONE * ENEMY_SCALE
	
	collision_layer = 1
	collision_mask = 1 | 2

	if DEBUG_SHOW_MODEL:
		_force_debug_material(self)
	elif HIDE_MODEL:
		_set_model_visibility(self, false)

	nav_agent = NavigationAgent3D.new()
	nav_agent.path_desired_distance = 0.5
	nav_agent.target_desired_distance = 0.5
	add_child(nav_agent)
	
	# Prevent wandering to (0,0,0) before seeing player
	nav_agent.target_position = global_position

	_setup_ledge_detector()
	_setup_isolated_world_cloud()

	floor_snap_length = 0.4
	floor_stop_on_slope = true

	_locate_player()

func _locate_player():
	player = get_tree().get_first_node_in_group("player")

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
			mat.albedo_color = Color(1.0, 0.0, 1.0) # Bright Magenta
			child.material_override = mat
		_force_debug_material(child)

func _setup_ledge_detector():
	ledge_ray = RayCast3D.new()
	ledge_ray.add_exception(self)
	ledge_ray.position = Vector3(0, 0.3, 0)
	ledge_ray.target_position = Vector3(0, -10.0, 0) # Extended to prevent false positive ledges when scaled
	ledge_ray.collision_mask = 1
	add_child(ledge_ray)

func _setup_isolated_world_cloud():
	dot_mesh = MultiMeshInstance3D.new()
	dot_mesh.top_level = true
	dot_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = false

	var quad = QuadMesh.new()
	base_quad_size = 0.06
	quad.size = Vector2(base_quad_size, base_quad_size)

	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.albedo_color = Color(1.0, 0.0, 0.0, 1.0)
	quad.material = mat
	mm.mesh = quad

	mm.instance_count = max_dots
	dot_mesh.multimesh = mm
	add_child(dot_mesh)

	dot_timers.resize(max_dots)
	dot_timers.fill(0.0)
	dot_max_timers.resize(max_dots)
	dot_max_timers.fill(BASE_DOT_LIFETIME)
	dot_world_positions.resize(max_dots)
	dot_world_positions.fill(Vector3(0, -9999, 0))
	dot_active.resize(max_dots)
	dot_active.fill(0)

	# PREVENT SINGULAR MATRIX CRASH (Scale must never be exactly 0.0)
	var hidden_t = Transform3D(Basis().scaled(Vector3.ONE * 0.001), Vector3(0, -9999, 0))
	for i in range(max_dots):
		mm.set_instance_transform(i, hidden_t)

func add_enemy_dot(hit_pos: Vector3):
	if not dot_mesh or not dot_mesh.multimesh:
		return

	var idx = dot_index
	var life = maxf(1.0, BASE_DOT_LIFETIME + randf_range(-LIFETIME_JITTER, LIFETIME_JITTER))

	dot_world_positions[idx] = hit_pos
	dot_timers[idx] = life
	dot_max_timers[idx] = life
	dot_active[idx] = 1

	var t = Transform3D(Basis(), hit_pos)
	dot_mesh.multimesh.set_instance_transform(idx, t)

	dot_index = (dot_index + 1) % max_dots

func _physics_process(delta: float):
	if is_nan(global_position.x) or is_nan(velocity.x):
		global_position = Vector3(0, 2.0, 0)
		velocity = Vector3.ZERO
		return

	_update_individual_dots(delta)

	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y = maxf(velocity.y - (gravity * delta), -15.0)

	if active_dots_count > 0:
		velocity.x = 0.0
		velocity.z = 0.0
	else:
		if _process_creep_movement(delta):
			return # Early out if the scene is reloading

	move_and_slide()
	_check_player_contact()

func _process_creep_movement(delta: float) -> bool:
	if not player:
		_locate_player()
		return false

	var diff = player.global_position - global_position
	diff.y = 0.0
	var dist_to_player = diff.length()
	
	if dist_to_player <= CATCH_DISTANCE:
		if player.has_method("die"):
			player.die()
		else:
			if has_node("/root/SaveManager"):
				SaveManager.reload_current_save()
			else:
				get_tree().reload_current_scene()
		return true

	# Always update the nav target to the player's position so it always paths to them.
	# We temporarily disable the Line-of-Sight restriction to guarantee movement works!
	nav_agent.target_position = player.global_position
		
	var next_path_pos = nav_agent.get_next_path_position()
	var path_diff = next_path_pos - global_position
	path_diff.y = 0.0
	
	var is_path_valid = not nav_agent.is_navigation_finished()
	
	# If the path is "valid" but the next point is exactly our current position, the path is empty/broken.
	if is_path_valid and path_diff.length_squared() <= 0.001 and dist_to_player > 1.0:
		is_path_valid = false
	
	# FALLBACK: If you didn't bake the NavMesh correctly, this prevents the enemy from permanently freezing.
	# It will just use basic straight-line chasing as long as it can see you.
	if not is_path_valid and dist_to_player > 1.0:
		path_diff = player.global_position - global_position
		path_diff.y = 0.0
		is_path_valid = true

	if is_path_valid and path_diff.length_squared() > 0.001:
		move_direction = path_diff.normalized()
		var target_yaw: float = atan2(-move_direction.x, -move_direction.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, ROTATION_SPEED * delta)
		
		velocity.x = move_direction.x * CHASE_SPEED
		velocity.z = move_direction.z * CHASE_SPEED
	else:
		velocity.x = 0.0
		velocity.z = 0.0
	return false

func _update_individual_dots(delta: float):
	if not dot_mesh or not dot_mesh.multimesh:
		return

	var mm = dot_mesh.multimesh
	var count = 0
	# Minimum scale 0.001 avoids zero-matrix crashes
	var hidden_t = Transform3D(Basis().scaled(Vector3.ONE * 0.001), Vector3(0, -9999, 0))

	for i in range(max_dots):
		if dot_active[i] == 0:
			continue

		dot_timers[i] -= delta

		if dot_timers[i] <= 0.0:
			dot_active[i] = 0
			dot_timers[i] = 0.0
			mm.set_instance_transform(i, hidden_t)
		else:
			count += 1
			# Keep dots at full size until they expire so visual state matches freezing logic exactly
			var t = Transform3D(Basis(), dot_world_positions[i])
			mm.set_instance_transform(i, t)

	active_dots_count = count

func _check_player_contact():
	for i in range(get_slide_collision_count()):
		var col = get_slide_collision(i)
		var collider = col.get_collider()
		if collider and (collider.is_in_group("player") or collider.name.to_lower().contains("player")):
			if collider.has_method("die"):
				collider.die()
			else:
				if has_node("/root/SaveManager"):
					SaveManager.reload_current_save()
				else:
					get_tree().reload_current_scene()
			return

func _check_line_of_sight() -> bool:
	if not player: return false
	var space_state = get_world_3d().direct_space_state
	var origin = global_position + Vector3(0, 1.0, 0)
	var target = player.global_position + Vector3(0, 1.0, 0)
	
	# Check all layers (0xFFFFFFFF) in case the player was moved to a different collision layer
	var query = PhysicsRayQueryParameters3D.create(origin, target, 4294967295, [self.get_rid()])
	var result = space_state.intersect_ray(query)
	
	if result:
		var collider = result.collider
		if collider.is_in_group("player") or collider.name.to_lower().contains("player"):
			return true
	return false
