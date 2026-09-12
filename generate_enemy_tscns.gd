extends SceneTree

func _init():
	var entities = ["BoomThing", "Hanger", "Skull"]
	var models = ["JamjamBoom.glb", "Hanger.entity.glb", "JamjamHangingSkull.glb"]
	var scripts = ["boom_thing.gd", "hanger.gd", "skull.gd"]
	
	for i in range(entities.size()):
		var name = entities[i]
		var glb_path = "res://Entities/" + models[i]
		var script_path = "res://Entities/" + scripts[i]
		
		var root = CharacterBody3D.new()
		root.name = name
		root.add_to_group("enemy")
		root.set_script(load(script_path))
		
		# Load the glb
		var glb_scene = load(glb_path)
		if not glb_scene:
			print("Could not load " + glb_path)
			continue
			
		var glb_instance = glb_scene.instantiate()
		glb_instance.name = name + "Model"
		root.add_child(glb_instance)
		glb_instance.owner = root
		
		# Rotate models if needed
		if name == "Hanger" or name == "Skull":
			# They need to be upside down because they hang from the ceiling
			glb_instance.transform.basis = Basis(Vector3(1, 0, 0), PI)
			
		# Extract meshes and create collision shapes
		_extract_collisions(glb_instance, root, root)
		
		var packed = PackedScene.new()
		packed.pack(root)
		ResourceSaver.save(packed, "res://Entities/" + name + ".tscn")
		print("Saved " + name + ".tscn")
		
	quit()

func _extract_collisions(node: Node, root: Node, char_body: CharacterBody3D):
	if node is MeshInstance3D and node.mesh:
		var mesh = node.mesh
		var coll_shape = CollisionShape3D.new()
		coll_shape.shape = mesh.create_convex_shape(true, true)
		# The transform of the collision shape must match the global transform of the mesh relative to the root
		coll_shape.transform = char_body.global_transform.affine_inverse() * node.global_transform
		coll_shape.name = node.name + "_Collision"
		char_body.add_child(coll_shape)
		coll_shape.owner = root
		
	for child in node.get_children():
		_extract_collisions(child, root, char_body)
