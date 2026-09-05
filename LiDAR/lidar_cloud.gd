extends MultiMeshInstance3D

const COLOR_WHITE = Color(1.0, 1.0, 1.0)
const COLOR_RED   = Color(1.0, 0.0, 0.0)

var current_idx: int = 0
var max_count: int = 40000

func _ready():
	multimesh.instance_count = max_count
	multimesh.visible_instance_count = 0

func spawn_dot(pos: Vector3, is_danger: bool):
	var idx = current_idx % max_count
	var t = Transform3D(Basis(), pos)
	
	multimesh.set_instance_transform(idx, t)
	multimesh.set_instance_color(idx, COLOR_RED if is_danger else COLOR_WHITE)
	
	current_idx += 1
	multimesh.visible_instance_count = mini(current_idx, max_count)
