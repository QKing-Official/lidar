extends Control

@export_file("*.tscn") var next_scene_path: String
@export var display_time: float = 3.0
@export var fade_time: float = 1.0

@onready var fade_rect = $FadeRect
var is_skipping = false

var active_tween: Tween
var thump_player: AudioStreamPlayer

func _ready():
	thump_player = AudioStreamPlayer.new()
	AudioManager.play_sfx("res://Assets/Audio/thump.wav")
	add_child(thump_player)
	
	# Ensure the fade rect starts black and visible
	fade_rect.color = Color(0, 0, 0, 1)
	fade_rect.show()
	
	# Start fade sequence
	_play_sequence()

func _play_sequence():
	active_tween = create_tween()
	
	thump_player.play()
	
	# Fade in
	active_tween.tween_property(fade_rect, "color:a", 0.0, fade_time)
	
	# Wait
	active_tween.tween_interval(display_time)
	
	# Fade out
	active_tween.tween_property(fade_rect, "color:a", 1.0, fade_time)
	
	# Go to next scene
	active_tween.tween_callback(_goto_next_scene)

func _input(event):
	if is_skipping:
		return
		
	# Any key or mouse button down
	if (event is InputEventKey and event.pressed) or (event is InputEventMouseButton and event.pressed):
		is_skipping = true
		_skip_to_next()

func _skip_to_next():
	if active_tween:
		active_tween.kill()
		
	# Fast fade out
	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, 0.2)
	tween.tween_callback(_goto_next_scene)

func _goto_next_scene():
	if next_scene_path != "":
		get_tree().change_scene_to_file(next_scene_path)
