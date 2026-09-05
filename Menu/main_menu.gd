extends Control

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	_style_button(%StartBtn)
	_style_button(%QuitBtn)
	
	%StartBtn.pressed.connect(_on_start)
	%QuitBtn.pressed.connect(_on_quit)

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
