extends Node3D

@onready var player = $Player
@onready var lidar_cloud = $LidarCloud

func _ready():
	var scene_path = get_tree().current_scene.scene_file_path if get_tree().current_scene else ""
	if scene_path.ends_with("Room1.tscn"):
		AudioManager.play_music("res://Assets/Audio/Music/Dithered.ogg")
	elif scene_path.ends_with("Room2.tscn"):
		AudioManager.play_music("res://Assets/Audio/Music/Liminality.ogg")
	elif scene_path.ends_with("Finale.tscn"):
		AudioManager.play_music("res://Assets/Audio/Music/Finality.ogg")

	if not player.scan_hit.is_connected(lidar_cloud.spawn_dot):
		player.scan_hit.connect(lidar_cloud.spawn_dot)
		
	# Automatically spawn Skull/Boom enemies in rows if this is Room2
	if get_tree().current_scene and get_tree().current_scene.scene_file_path.ends_with("Room2.tscn"):
		# Remove normal enemies
		for child in get_children():
			if child.name.begins_with("Enemy"):
				child.queue_free()
				
		var skull_scene = load("res://Entities/Skull.tscn")
		var boom_scene = load("res://Entities/BoomThing.tscn")
		
		var spawners = get_tree().get_nodes_in_group("spawner")
		for spawner in spawners:
			# Ensure exactly 3 skulls per row
			var enemies = [
				skull_scene.instantiate(),
				skull_scene.instantiate(),
				skull_scene.instantiate()
			]
			
			# Spread them across the chamber width (Z axis)
			var offsets = [-18.0, 0.0, 18.0]
			for i in range(3):
				var enemy = enemies[i]
				add_child(enemy)
				# Space them along the global Z-axis (width of the corridor)
				enemy.global_position = spawner.global_position + (Vector3(0, 0, 1) * offsets[i])
