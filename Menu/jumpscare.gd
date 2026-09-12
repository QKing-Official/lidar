extends Node3D

var dots = []

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if has_node("/root/AudioManager"):
		AudioManager.play_sfx("res://Assets/Audio/static.wav", 10.0, 1.2)
	
	if has_node("/root/SaveManager"):
		var enemy_path = SaveManager.jumpscare_enemy_scene_file
		if enemy_path != "":
			var enemy_scene = load(enemy_path)
			if enemy_scene:
				var enemy = enemy_scene.instantiate()
				add_child(enemy)
				
				# Handle different enemy positioning
				if "hanger" in enemy_path.to_lower():
					# The head is at local X=-11. Since we rotate 180 (PI), local -X becomes global +X.
					# To center the head at X=0, we move the origin to X=-5.5, but scaled down
					enemy.scale = Vector3(0.5, 0.5, 0.5)
					# Head local Y is around -0.5. At 0.5 scale that's -0.25. Set Y=0.25 so head is at 0
					enemy.global_position = Vector3(-5.5, 0.25, -2.5)
					enemy.rotation = Vector3(0, PI, 0)
				elif "boom" in enemy_path.to_lower():
					enemy.global_position = Vector3(0, -0.2, -1.5)
					enemy.look_at($Camera3D.global_position, Vector3.UP)
				elif "skull" in enemy_path.to_lower():
					# Skulls are small by default, scale up for jumpscare
					enemy.scale = Vector3(1.5, 1.5, 1.5)
					enemy.global_position = Vector3(0, 0, -1.5)
					enemy.look_at($Camera3D.global_position, Vector3.UP)
				else:
					enemy.global_position = Vector3(0, -0.5, -1.5)
					enemy.look_at($Camera3D.global_position, Vector3.UP)
				
				# Ensure it just renders and doesn't try to move
				enemy.set_process(false)
				enemy.set_physics_process(false)
				
				_make_red(enemy)
	
	# Add black dot dithering (static noise effect)
	var canvas = CanvasLayer.new()
	canvas.layer = 10
	add_child(canvas)
	
	for i in range(400):
		var dot = ColorRect.new()
		dot.color = Color.BLACK
		dot.size = Vector2(randf_range(4, 12), randf_range(4, 12))
		canvas.add_child(dot)
		dots.append(dot)
	
	var tween = get_tree().create_tween()
	tween.tween_interval(1.5)
	tween.tween_callback(func():
		if has_node("/root/SaveManager"):
			SaveManager.reload_current_save()
		else:
			get_tree().change_scene_to_file("res://World/Tutorial.tscn")
	)

func _process(delta):
	if dots.size() > 0:
		var vs = get_viewport().size
		for dot in dots:
			dot.position = Vector2(randf_range(0, vs.x), randf_range(0, vs.y))

func _make_red(node: Node):
	if node is MeshInstance3D:
		node.show()
		var mat = StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(1, 0, 0, 1)
		node.material_override = mat
	for child in node.get_children():
		_make_red(child)
