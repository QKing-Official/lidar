extends Area3D

@export var next_level_path: String = ""

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player") or body.name.to_lower().contains("player"):
		if next_level_path != "":
			SaveManager.load_level(next_level_path)
		else:
			print("Error: No next level path set for transition!")
