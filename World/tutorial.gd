extends Node3D

var tutorial3_played = false
var tutorial4_played = false
var has_started = false

var moved_yet = false
var shot_yet = false
var ui_layer: CanvasLayer
var ui_container: Control

@onready var player = $Player
@onready var lidar_cloud = $LidarCloud
@onready var exit = $LevelTransition

func _ready():
	AudioManager.play_music("res://Assets/Audio/Music/JustAwake.ogg")
		
	if not player.scan_hit.is_connected(lidar_cloud.spawn_dot):
		player.scan_hit.connect(lidar_cloud.spawn_dot)

	play_tutorial_sequence()

func play_tutorial_sequence():
	while not player.is_on_floor():
		await get_tree().physics_frame

	player.process_mode = Node.PROCESS_MODE_DISABLED
	has_started = true
	AudioManager.play_voiceline("res://Assets/Voicelines/Tutorial1.wav")
	await AudioManager.voice_player.finished

	player.process_mode = Node.PROCESS_MODE_INHERIT
	AudioManager.play_voiceline("res://Assets/Voicelines/Tutorial2.wav")
	_show_controls_ui()
	await AudioManager.voice_player.finished

	# Play tutorial 3 shortly after 2 finishes
	await get_tree().create_timer(15.0).timeout
	AudioManager.play_voiceline("res://Assets/Voicelines/tutorial3.wav")

func _get_key_name(action: String) -> String:
	var evts = InputMap.action_get_events(action)
	if evts.size() == 0: return "?"
	var evt = evts[0]
	if evt is InputEventKey:
		return OS.get_keycode_string(evt.physical_keycode)
	elif evt is InputEventMouseButton:
		if evt.button_index == MOUSE_BUTTON_LEFT: return "LMB"
		if evt.button_index == MOUSE_BUTTON_RIGHT: return "RMB"
		if evt.button_index == MOUSE_BUTTON_MIDDLE: return "MMB"
	return evt.as_text().split(" ")[0]

func _create_key_ui(text: String, size: Vector2 = Vector2(60, 60)) -> Label:
	var lbl = Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.custom_minimum_size = size
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 1)
	sb.border_color = Color(1, 1, 1, 1)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	lbl.add_theme_stylebox_override("normal", sb)
	return lbl

func _show_controls_ui():
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	
	ui_container = MarginContainer.new()
	ui_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_container.add_theme_constant_override("margin_bottom", 80)
	ui_layer.add_child(ui_container)
	
	var main_hbox = HBoxContainer.new()
	main_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_hbox.add_theme_constant_override("separation", 200)
	main_hbox.size_flags_vertical = Control.SIZE_SHRINK_END
	ui_container.add_child(main_hbox)
	
	# MOVE CLUSTER
	var move_vbox = VBoxContainer.new()
	move_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_hbox.add_child(move_vbox)
	
	var move_lbl = Label.new()
	move_lbl.text = "MOVE"
	move_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	move_lbl.add_theme_font_size_override("font_size", 24)
	move_vbox.add_child(move_lbl)
	
	var w_row = HBoxContainer.new()
	w_row.alignment = BoxContainer.ALIGNMENT_CENTER
	move_vbox.add_child(w_row)
	w_row.add_child(_create_key_ui(_get_key_name("move_forward")))
	
	var asd_row = HBoxContainer.new()
	asd_row.alignment = BoxContainer.ALIGNMENT_CENTER
	move_vbox.add_child(asd_row)
	asd_row.add_child(_create_key_ui(_get_key_name("move_left")))
	asd_row.add_child(_create_key_ui(_get_key_name("move_backward")))
	asd_row.add_child(_create_key_ui(_get_key_name("move_right")))
	
	# SCAN CLUSTER
	var scan_vbox = VBoxContainer.new()
	scan_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_hbox.add_child(scan_vbox)
	
	var scan_lbl = Label.new()
	scan_lbl.text = "SCAN"
	scan_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scan_lbl.add_theme_font_size_override("font_size", 24)
	scan_vbox.add_child(scan_lbl)
	
	var scan_key = _create_key_ui("LMB", Vector2(180, 60))
	scan_vbox.add_child(scan_key)

func _process(delta):
	if has_started and not tutorial4_played:
		if is_instance_valid(player):
			var dangers = get_tree().get_nodes_in_group("danger")
			for d in dangers:
				if is_instance_valid(d) and d is Node3D:
					if player.global_position.distance_to(d.global_position) < 20.0:
						tutorial4_played = true
						AudioManager.play_voiceline("res://Assets/Voicelines/tutorial4.wav")
						break

	if is_instance_valid(ui_layer) and is_instance_valid(ui_container):
		var did_move = Input.get_vector("move_left", "move_right", "move_forward", "move_backward").length_squared() > 0.1
		var did_shoot = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		
		if did_move or did_shoot:
			var tween = get_tree().create_tween()
			tween.tween_property(ui_container, "modulate:a", 0.0, 1.0)
			tween.tween_callback(ui_layer.queue_free)
			ui_layer = null
