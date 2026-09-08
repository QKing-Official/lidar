extends Node3D

signal scan_hit(pos: Vector3, is_danger: bool)

@export var RAY_COUNT: int = 150
@export var MAX_SPREAD_DEG: float = 60.0
@export var SCAN_RANGE: float = 40.0

@onready var scanner_ray = $ScannerRay

func _ready():
	scanner_ray.target_position = Vector3(0, 0, -SCAN_RANGE)
	scanner_ray.collision_mask = 3
	scanner_ray.collide_with_areas = true
	scanner_ray.collide_with_bodies = true

func _physics_process(delta):
	# Slowly rotate the scanner so it sweeps the room
	rotate_y(0.3 * delta)
	_fire_circular_scan()

func _fire_circular_scan():
	var max_spread_rad = deg_to_rad(MAX_SPREAD_DEG)
	var aspect_ratio = 16.0 / 9.0

	for i in range(RAY_COUNT):
		var r = sqrt(randf()) 
		var angle = randf_range(0.0, TAU)

		var spread_angle = r * max_spread_rad
		var off_x = cos(angle) * spread_angle * (aspect_ratio * 0.7)
		var off_y = sin(angle) * spread_angle

		var dir = Vector3.FORWARD.rotated(Vector3.RIGHT, off_y).rotated(Vector3.UP, -off_x).normalized()

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
