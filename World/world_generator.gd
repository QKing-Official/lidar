extends Node3D

func _ready():
	var invis_mat = preload("res://Materials/InvisibleMaterial.tres")
	_process_node(self, invis_mat)
	print("Map generation complete: Materials applied and collisions generated.")

func _process_node(node: Node, mat: Material):
	if node is MeshInstance3D:
		# Apply invisible material
		node.material_override = mat
		
		# Generate trimesh collision so player and LiDAR hit it
		node.create_trimesh_collision()
		
		# Ensure the generated collision body is on the correct layers
		for child in node.get_children():
			if child is StaticBody3D:
				child.collision_layer = 1
				child.collision_mask = 1
	
	for child in node.get_children():
		_process_node(child, mat)
