extends Control

var lines = [
	"PROGRAMMING\nqkingsoftware",
	"MODELS\nvitovgg",
	"MUSIC & SFX\nqkingsoftware",
	"ASSISTANT VOICE\nqkingsoftware",
	"GAME IDEA\nvitovgg & qkingsoftware",
	"LORE\nvitovgg",
	"SPECIAL THANKS\nEveryone playing this game\nPixelForge Jam 3",
	"True freedom comes at the ultimate cost."
]

var current_line = 0
@onready var label = $CenterContainer/Label

func _ready():
	AudioManager.play_music("res://Assets/Audio/Music/InnerPeace.ogg")
		
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	label.modulate.a = 0.0
	
	# Delete the save slot since they beat the game!
	if SaveManager.current_slot > 0:
		SaveManager.delete_save(SaveManager.current_slot)
	
	SaveManager.mark_game_completed()
	
	var tween = get_tree().create_tween()
	tween.tween_interval(1.0)
	tween.tween_callback(self._next_line)

func _next_line():
	if current_line >= lines.size():
		_finish_credits()
		return
		
	label.text = lines[current_line]
	
	var is_last = (current_line == lines.size() - 1)
	var hold_time = 4.0 if is_last else 2.5
	
	if is_last:
		label.add_theme_color_override("font_color", Color(1, 0, 0, 1))
	
	current_line += 1
	
	var tween = get_tree().create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 1.5)
	tween.tween_interval(hold_time)
	tween.tween_property(label, "modulate:a", 0.0, 1.5)
	tween.tween_callback(self._next_line)

func _finish_credits():
	var tween = get_tree().create_tween()
	tween.tween_interval(1.5)
	tween.tween_callback(func():
		get_tree().change_scene_to_file("res://Menu/main_menu.tscn")
	)
