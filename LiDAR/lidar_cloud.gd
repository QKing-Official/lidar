extends MultiMeshInstance3D

const COLOR_WHITE = Color(1.0, 1.0, 1.0, 1.0)
const COLOR_RED   = Color(1.0, 0.0, 0.0, 1.0)

var current_idx: int = 0
var max_count: int = 40000

func _ready():
	if not multimesh:
		var mm = MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true

		var quad = QuadMesh.new()
		quad.size = Vector2(0.04, 0.04)
		var mat = StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		mat.vertex_color_use_as_albedo = true
		quad.material = mat

		mm.mesh = quad
		multimesh = mm

	multimesh.instance_count = max_count
	multimesh.visible_instance_count = 0

	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_signal("scan_hit"):
		player.scan_hit.connect(spawn_dot)

func spawn_dot(pos: Vector3, is_danger: bool):
	var idx = current_idx % max_count
	var t = Transform3D(Basis(), pos)

	multimesh.set_instance_transform(idx, t)
	multimesh.set_instance_color(idx, COLOR_RED if is_danger else COLOR_WHITE)

	current_idx += 1
	multimesh.visible_instance_count = mini(current_idx, max_count)
