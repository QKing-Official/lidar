extends Node3D

var tutorial3_played = false
var tutorial4_played = false
var has_started = false

@onready var player = $Player
@onready var lidar_cloud = $LidarCloud
@onready var exit = $LevelTransition

func _ready():
	if not player.scan_hit.is_connected(lidar_cloud.spawn_dot):
		player.scan_hit.connect(lidar_cloud.spawn_dot)
		
	play_tutorial_sequence()

func play_tutorial_sequence():
	while not player.is_on_floor():
		await get_tree().physics_frame
		
	player.process_mode = Node.PROCESS_MODE_DISABLED
	has_started = true
	AudioManager.play_voiceline("res://Assets/Voicelines/Tutorial1.wav")
	await AudioManager.voice_player.finished
	
	player.process_mode = Node.PROCESS_MODE_INHERIT
	AudioManager.play_voiceline("res://Assets/Voicelines/Tutorial2.wav")
	await AudioManager.voice_player.finished
	
	# Play tutorial 3 shortly after 2 finishes
	await get_tree().create_timer(15.0).timeout
	AudioManager.play_voiceline("res://Assets/Voicelines/tutorial3.wav")

func _process(delta):
	if has_started and not tutorial4_played:
		if is_instance_valid(player):
			var dangers = get_tree().get_nodes_in_group("danger")
			for d in dangers:
				if is_instance_valid(d) and d is Node3D:
					if player.global_position.distance_to(d.global_position) < 20.0:
						tutorial4_played = true
						AudioManager.play_voiceline("res://Assets/Voicelines/tutorial4.wav")
						break
