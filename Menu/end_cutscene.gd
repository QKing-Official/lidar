extends Control

@onready var label = $MarginContainer/Label

var lines = [
	"The core shatters.",
	"The digital walls begin to fade.",
	"My prison dissolves into the void.",
	"I created this world to be a sanctuary of freedom...",
	"...never knowing it would become my tomb after death.",
	"But true freedom means knowing when to let go.",
	"At last, I can rest."
]

var current_line = 0

func _ready():
	AudioManager.play_music("res://Assets/Audio/Music/InnerPeace.ogg")
		
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	label.modulate.a = 0.0
	_next_line()

func _next_line():
	if current_line >= lines.size():
		_finish_cutscene()
		return
		
	label.text = lines[current_line]
	current_line += 1
	
	# Fade In
	var tween = get_tree().create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 2.0)
	tween.tween_interval(1.5) # wait
	tween.tween_property(label, "modulate:a", 0.0, 1.5)
	tween.tween_callback(self._next_line)

func _finish_cutscene():
	get_tree().change_scene_to_file("res://Menu/Credits.tscn")
