extends Node3D

@onready var player = $Player
@onready var lidar_cloud = $LidarCloud

func _ready():
	if not player.scan_hit.is_connected(lidar_cloud.spawn_dot):
		player.scan_hit.connect(lidar_cloud.spawn_dot)
