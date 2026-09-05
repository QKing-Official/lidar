extends Node3D

@onready var player = $Player
@onready var lidar_cloud = $LidarCloud

func _ready():
	player.scan_hit.connect(lidar_cloud.spawn_dot)
