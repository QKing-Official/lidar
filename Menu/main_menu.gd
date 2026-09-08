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

func _on_start():
	%VBoxContainer.hide()
	_show_save_slots()

func _on_quit():
	get_tree().quit()

func _show_save_slots():
	var save_container = MarginContainer.new()
	save_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	save_container.add_theme_constant_override("margin_left", 100)
	save_container.add_theme_constant_override("margin_right", 100)
	add_child(save_container)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	save_container.add_child(vbox)
	
	var title = Label.new()
	title.text = "SELECT SAVE FILE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(1, 0, 0, 1))
	vbox.add_child(title)
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 40)
	vbox.add_child(spacer)
	
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 40)
	vbox.add_child(hbox)
	
	for i in range(1, 4):
		_create_slot_ui(i, hbox)

	var back_btn = Button.new()
	back_btn.text = "BACK"
	back_btn.custom_minimum_size = Vector2(200, 50)
	back_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_style_button(back_btn)
	back_btn.pressed.connect(func():
		click_player.play()
		save_container.queue_free()
		%VBoxContainer.show()
	)
	back_btn.mouse_entered.connect(_on_hover)
	
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 40)
	vbox.add_child(spacer2)
	vbox.add_child(back_btn)

func _create_slot_ui(slot: int, parent: Control):
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(300, 400)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 1)
	style.border_color = Color(1, 0, 0, 1)
	style.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	var img_rect = TextureRect.new()
	img_rect.custom_minimum_size = Vector2(296, 200)
	img_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	vbox.add_child(img_rect)
	
	var info_label = Label.new()
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(info_label)
	
	var png_path = SaveManager.SAVE_DIR + "save_slot_" + str(slot) + ".png"
	var has_save = FileAccess.file_exists(SaveManager.SAVE_DIR + "save_slot_" + str(slot) + ".json")
	
	if has_save and FileAccess.file_exists(png_path):
		var img = Image.load_from_file(png_path)
		var tex = ImageTexture.create_from_image(img)
		img_rect.texture = tex
		info_label.text = "SLOT " + str(slot) + "\nCONTINUE"
	else:
		info_label.text = "SLOT " + str(slot) + "\nNEW GAME"
		var fallback_style = StyleBoxFlat.new()
		fallback_style.bg_color = Color(0.1, 0.1, 0.1, 1)
		img_rect.texture = null
	
	var play_btn = Button.new()
	play_btn.text = "PLAY"
	_style_button(play_btn)
	play_btn.pressed.connect(func():
		click_player.play()
		SaveManager.load_game(slot)
	)
	play_btn.mouse_entered.connect(_on_hover)
	vbox.add_child(play_btn)
	
	if has_save:
		var del_btn = Button.new()
		del_btn.text = "DELETE"
		var del_style_normal = StyleBoxFlat.new()
		del_style_normal.bg_color = Color(0, 0, 0, 1)
		del_style_normal.border_color = Color(0.5, 0, 0, 1)
		del_style_normal.set_border_width_all(2)
		var del_style_hover = StyleBoxFlat.new()
		del_style_hover.bg_color = Color(0.5, 0, 0, 1)
		del_style_hover.border_color = Color(1, 0, 0, 1)
		del_style_hover.set_border_width_all(2)
		del_btn.add_theme_stylebox_override("normal", del_style_normal)
		del_btn.add_theme_stylebox_override("hover", del_style_hover)
		del_btn.pressed.connect(func():
			click_player.play()
			SaveManager.delete_save(slot)
			parent.get_parent().get_parent().queue_free()
			_show_save_slots()
		)
		del_btn.mouse_entered.connect(_on_hover)
		vbox.add_child(del_btn)

func _style_button(btn: Button):
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0, 0, 0, 1)
	style_normal.border_color = Color(1, 0, 0, 1) # Red
	style_normal.set_border_width_all(2)
	style_normal.set_content_margin_all(8)
	
	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0, 0, 0, 1)
	style_hover.border_color = Color(1, 1, 1, 1) # White
	style_hover.set_border_width_all(2)
	style_hover.set_content_margin_all(8)
	
	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("pressed", style_hover)
	btn.add_theme_stylebox_override("focus", style_hover)
	
	btn.add_theme_color_override("font_color", Color(1, 0, 0, 1))         # Red
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))   # White
	btn.add_theme_color_override("font_pressed_color", Color(1, 1, 1, 1)) # White
	btn.add_theme_color_override("font_focus_color", Color(1, 1, 1, 1))   # White
