extends CanvasLayer

var click_player: AudioStreamPlayer

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	visible = false
	
	click_player = AudioStreamPlayer.new()
	click_player.stream = preload("res://Assets/Audio/click.wav")
	add_child(click_player)
	
	%ContinueBtn.pressed.connect(_on_continue)
	%SettingsBtn.pressed.connect(_on_settings)
	%ExitBtn.pressed.connect(_on_exit)
	
	%ContinueBtn.mouse_entered.connect(_on_hover)
	%SettingsBtn.mouse_entered.connect(_on_hover)
	%ExitBtn.mouse_entered.connect(_on_hover)
	
	_style_button(%ContinueBtn)
	_style_button(%SettingsBtn)
	_style_button(%ExitBtn)
	
	$SettingsMenu.hide()
	$SettingsMenu.back_pressed.connect(func():
		$SettingsMenu.hide()
		%MainPanel.show()
	)

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		if $SettingsMenu.visible:
			$SettingsMenu.hide()
			%MainPanel.show()
			return
			
		if get_tree().current_scene.name == "MainMenu":
			return # Don't pause in main menu
			
		visible = !visible
		if visible:
			get_tree().paused = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			get_tree().paused = false
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_hover():
	click_player.play()

func _on_continue():
	click_player.play()
	visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_settings():
	click_player.play()
	%MainPanel.hide()
	$SettingsMenu.show()

func _on_exit():
	click_player.play()
	visible = false
	get_tree().paused = false
	if SaveManager.current_level_path != "" and SaveManager.current_slot > 0:
		SaveManager.save_game(SaveManager.current_slot)
	
	get_tree().change_scene_to_file("res://Menu/main_menu.tscn")

func _style_button(btn: Button):
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0, 0, 0, 1)
	style_normal.border_color = Color(1, 0, 0, 1)
	style_normal.set_border_width_all(2)
	style_normal.set_content_margin_all(8)
	
	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0, 0, 0, 1)
	style_hover.border_color = Color(1, 1, 1, 1)
	style_hover.set_border_width_all(2)
	style_hover.set_content_margin_all(8)
	
	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("pressed", style_hover)
	btn.add_theme_stylebox_override("focus", style_hover)
	
	btn.add_theme_color_override("font_color", Color(1, 0, 0, 1))
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
	btn.add_theme_color_override("font_pressed_color", Color(1, 1, 1, 1))
	btn.add_theme_color_override("font_focus_color", Color(1, 1, 1, 1))
