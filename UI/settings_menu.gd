extends Control

signal back_pressed

var click_player: AudioStreamPlayer
var listening_action: String = ""

func _ready():
	click_player = AudioStreamPlayer.new()
	click_player.stream = preload("res://Assets/Audio/click.wav")
	add_child(click_player)
	
	%BackBtn.pressed.connect(func():
		click_player.play()
		back_pressed.emit()
	)
	
	%ResetBtn.pressed.connect(func():
		click_player.play()
		SettingsManager.reset_to_defaults()
		_refresh_ui_from_settings()
	)
	
	# Setup Graphics
	%FovSlider.value = SettingsManager.fov
	%FovSlider.value_changed.connect(func(val):
		SettingsManager.fov = val
		%FovLabel.text = str(int(val))
		SettingsManager.save_settings()
	)
	%FovLabel.text = str(int(SettingsManager.fov))
	
	%SensSlider.value = SettingsManager.mouse_sensitivity
	%SensSlider.value_changed.connect(func(val):
		SettingsManager.mouse_sensitivity = val
		%SensLabel.text = str(snapped(val, 0.0001))
		SettingsManager.save_settings()
	)
	%SensLabel.text = str(snapped(SettingsManager.mouse_sensitivity, 0.0001))
	
	_update_checkbox(%FullscreenCheck, SettingsManager.fullscreen)
	%FullscreenCheck.toggled.connect(func(pressed):
		click_player.play()
		SettingsManager.fullscreen = pressed
		SettingsManager.apply_graphics_settings()
		SettingsManager.save_settings()
		_update_checkbox(%FullscreenCheck, pressed)
	)
	
	_update_checkbox(%VSyncCheck, SettingsManager.vsync)
	%VSyncCheck.toggled.connect(func(pressed):
		click_player.play()
		SettingsManager.vsync = pressed
		SettingsManager.apply_graphics_settings()
		SettingsManager.save_settings()
		_update_checkbox(%VSyncCheck, pressed)
	)
	
	_setup_keybind_button("move_forward", %BtnForward)
	_setup_keybind_button("move_backward", %BtnBackward)
	_setup_keybind_button("move_left", %BtnLeft)
	_setup_keybind_button("move_right", %BtnRight)
	_setup_keybind_button("jump", %BtnJump)
	_setup_keybind_button("fire_lidar", %BtnFire)

func _refresh_ui_from_settings():
	%FovSlider.set_value_no_signal(SettingsManager.fov)
	%FovLabel.text = str(int(SettingsManager.fov))
	
	%SensSlider.set_value_no_signal(SettingsManager.mouse_sensitivity)
	%SensLabel.text = str(snapped(SettingsManager.mouse_sensitivity, 0.0001))
	
	_update_checkbox(%FullscreenCheck, SettingsManager.fullscreen)
	_update_checkbox(%VSyncCheck, SettingsManager.vsync)
	
	_update_keybind_label("move_forward", %BtnForward)
	_update_keybind_label("move_backward", %BtnBackward)
	_update_keybind_label("move_left", %BtnLeft)
	_update_keybind_label("move_right", %BtnRight)
	_update_keybind_label("jump", %BtnJump)
	_update_keybind_label("fire_lidar", %BtnFire)

func _setup_keybind_button(action: String, btn: Button):
	# Unhook previous connections to avoid double triggers if this is called repeatedly
	if btn.pressed.is_connected(_on_keybind_pressed):
		btn.pressed.disconnect(_on_keybind_pressed)
	
	_update_keybind_label(action, btn)
	btn.pressed.connect(_on_keybind_pressed.bind(action, btn))

func _on_keybind_pressed(action: String, btn: Button):
	click_player.play()
	listening_action = action
	btn.text = "PRESS ANY KEY..."

func _update_checkbox(btn: Button, pressed: bool):
	btn.button_pressed = pressed
	if pressed:
		btn.text = "V"
		btn.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		btn.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
		btn.add_theme_color_override("font_pressed_color", Color(1, 1, 1, 1))
		btn.add_theme_color_override("font_focus_color", Color(1, 1, 1, 1))
	else:
		btn.text = "X"
		btn.add_theme_color_override("font_color", Color(1, 0, 0, 1))
		btn.add_theme_color_override("font_hover_color", Color(1, 0, 0, 1))
		btn.add_theme_color_override("font_pressed_color", Color(1, 0, 0, 1))
		btn.add_theme_color_override("font_focus_color", Color(1, 0, 0, 1))

func _update_keybind_label(action: String, btn: Button):
	var events = InputMap.action_get_events(action)
	if events.size() > 0:
		var ev = events[0]
		if ev is InputEventKey:
			btn.text = OS.get_keycode_string(ev.physical_keycode)
		elif ev is InputEventMouseButton:
			if ev.button_index == MOUSE_BUTTON_LEFT: btn.text = "Left Mouse"
			elif ev.button_index == MOUSE_BUTTON_RIGHT: btn.text = "Right Mouse"
			elif ev.button_index == MOUSE_BUTTON_MIDDLE: btn.text = "Middle Mouse"
			else: btn.text = "Mouse " + str(ev.button_index)

func _input(event):
	if listening_action != "":
		if event is InputEventKey or event is InputEventMouseButton:
			if event.is_pressed():
				SettingsManager.remap_action(listening_action, event)
				# Update all buttons to reflect changes
				_update_keybind_label("move_forward", %BtnForward)
				_update_keybind_label("move_backward", %BtnBackward)
				_update_keybind_label("move_left", %BtnLeft)
				_update_keybind_label("move_right", %BtnRight)
				_update_keybind_label("jump", %BtnJump)
				_update_keybind_label("fire_lidar", %BtnFire)
				listening_action = ""
				get_viewport().set_input_as_handled()
