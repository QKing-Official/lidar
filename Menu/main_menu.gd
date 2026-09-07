extends Control

var click_player: AudioStreamPlayer
var static_player: AudioStreamPlayer

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	click_player = AudioStreamPlayer.new()
	click_player.stream = preload("res://Assets/Audio/click.wav")
	add_child(click_player)
	
	static_player = AudioStreamPlayer.new()
	static_player.stream = preload("res://Assets/Audio/static.wav")
	static_player.volume_db = -10.0
	add_child(static_player)
	static_player.play()
	
	_style_button(%StartBtn)
	_style_button(%QuitBtn)
	
	%StartBtn.pressed.connect(_on_start)
	%QuitBtn.pressed.connect(_on_quit)
	
	%StartBtn.mouse_entered.connect(_on_hover)
	%QuitBtn.mouse_entered.connect(_on_hover)
	
	var scanner = $SubViewportContainer/SubViewport/MenuWorld/MenuScanner
	var lidar = $SubViewportContainer/SubViewport/MenuWorld/LidarCloud
	scanner.scan_hit.connect(lidar.spawn_dot)

func _on_hover():
	click_player.play()

func _style_button(btn: Button):
	# 1. Normal State: Black fill, 2px Red border, Red text
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0, 0, 0, 1)
	style_normal.border_color = Color(1, 0, 0, 1) # Red
	style_normal.set_border_width_all(2)
	style_normal.set_content_margin_all(8)
	
	# 2. Hover State: Black fill, 2px White border, White text
	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0, 0, 0, 1)
	style_hover.border_color = Color(1, 1, 1, 1) # White
	style_hover.set_border_width_all(2)
	style_hover.set_content_margin_all(8)
	
	# Apply styles to states
	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("pressed", style_hover)
	btn.add_theme_stylebox_override("focus", style_hover)
	
	# Apply font colors
	btn.add_theme_color_override("font_color", Color(1, 0, 0, 1))         # Red
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))   # White
	btn.add_theme_color_override("font_pressed_color", Color(1, 1, 1, 1)) # White
	btn.add_theme_color_override("font_focus_color", Color(1, 1, 1, 1))   # White

func _on_start():
	get_tree().change_scene_to_file("res://World/World.tscn")

func _on_quit():
	get_tree().quit()
