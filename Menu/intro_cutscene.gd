extends Control

var lines = [
	"Freedom...",
	"I sought to create a world where one could truly be free.",
	"A world free from the constraints of reality.",
	"But at what cost?",
	"My own body failed me. I am gone.",
	"Yet here I am... trapped inside my own creation.",
	"Is this freedom?"
]

var current_line = 0
var is_fading = false
@onready var label = $MarginContainer/Label

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	label.modulate.a = 0.0
	_next_line()

func _input(event):
	if event is InputEventKey and event.pressed and not event.is_echo():
		_finish_cutscene()
	elif event is InputEventMouseButton and event.pressed:
		_finish_cutscene()

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
	get_tree().change_scene_to_file("res://World/Tutorial.tscn")
