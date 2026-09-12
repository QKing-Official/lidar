extends StaticBody3D

@export var max_hits: int = 5
var hits: int = 0
var broken: bool = false
var can_be_hit: bool = true
var original_pos: Vector3

@onready var mesh = $MeshInstance3D
@onready var player = get_tree().get_first_node_in_group("player")

func _ready():
	add_to_group("enemy") # To receive lidar dots
	original_pos = mesh.position

func _process(delta):
	pass

func add_enemy_dot(pos: Vector3):
	if broken or not can_be_hit: return
	
	if is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist > 15.0:
			return # Too far away
			
	hits += 1
	can_be_hit = false
	
	# Spawn black crossing lines (2D flat on the surface)
	var cross_node = Node3D.new()
	add_child(cross_node)
	cross_node.global_position = pos
	
	var dir_to_player = (player.global_position - pos).normalized()
	cross_node.global_position += dir_to_player * 0.1 # prevent z-fighting
	cross_node.look_at(player.global_position, Vector3.UP, true)
	cross_node.rotate_z(randf_range(0, PI)) # random angle
	
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0, 0, 0, 1)
	
	var quad1 = MeshInstance3D.new()
	var qm1 = QuadMesh.new()
	qm1.size = Vector2(2.5, 0.15)
	quad1.mesh = qm1
	quad1.material_override = mat
	cross_node.add_child(quad1)
	
	var quad2 = MeshInstance3D.new()
	var qm2 = QuadMesh.new()
	qm2.size = Vector2(2.5, 0.15)
	quad2.mesh = qm2
	quad2.material_override = mat
	cross_node.add_child(quad2)
	quad2.rotation_degrees.z = 90
	
	# Shake effect (milder)
	var tween = get_tree().create_tween()
	for i in range(5):
		tween.tween_property(mesh, "position", original_pos + Vector3(randf_range(-0.1, 0.1), randf_range(-0.1, 0.1), randf_range(-0.1, 0.1)), 0.05)
	tween.tween_property(mesh, "position", original_pos, 0.05)
	
	if hits >= max_hits:
		_break_core()
	else:
		# Cooldown before it can be hit again
		get_tree().create_timer(1.0).timeout.connect(func(): can_be_hit = true)

func _break_core():
	broken = true
	AudioManager.play_sfx("res://Assets/Audio/static.wav") # loud breaking noise
	mesh.hide()
	
	if has_node("OmniLight3D"):
		$OmniLight3D.hide()
	
	# Create the 3D expanding red sphere
	var explosion = MeshInstance3D.new()
	var sm = SphereMesh.new()
	sm.radius = 0.5
	sm.height = 1.0
	explosion.mesh = sm
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED # crucial so it engulfs the camera!
	mat.albedo_color = Color(1, 0, 0, 1)
	explosion.material_override = mat
	add_child(explosion)
	explosion.global_position = global_position
	
	# Add black dots to the surface of the sphere
	for i in range(100):
		var dot = MeshInstance3D.new()
		var bm = BoxMesh.new()
		bm.size = Vector3(0.05, 0.05, 0.05)
		dot.mesh = bm
		var dmat = StandardMaterial3D.new()
		dmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		dmat.albedo_color = Color(0, 0, 0, 1)
		dot.material_override = dmat
		explosion.add_child(dot)
		
		# Place randomly on the surface
		var dir = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)).normalized()
		dot.position = dir * 0.5
		
		# Random rotation so they look jagged
		dot.rotation = Vector3(randf_range(0, PI), randf_range(0, PI), randf_range(0, PI))
	
	# Full screen canvas for the transition
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	add_child(canvas)
	
	var overlay = ColorRect.new()
	overlay.color = Color(1, 0, 0, 0) # start fully transparent
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(overlay)
	
	var tween = get_tree().create_tween()
	# Phase 1: Expand the sphere massively over 1.5 seconds
	tween.tween_property(explosion, "scale", Vector3(200, 200, 200), 1.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	
	# Phase 2: Fade in the pure red overlay to transition to "full red"
	tween.tween_property(overlay, "color", Color(1, 0, 0, 1), 0.2)
	
	# Phase 3: Fade from red to black
	tween.tween_interval(0.5)
	tween.tween_property(overlay, "color", Color(0, 0, 0, 1), 1.5)
	
	# Phase 4: To the cutscene!
	tween.tween_interval(0.5)
	tween.tween_callback(func():
		get_tree().change_scene_to_file("res://Menu/EndCutscene.tscn")
	)
