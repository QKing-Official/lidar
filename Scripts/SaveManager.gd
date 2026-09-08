extends Node

var current_slot: int = 1
var current_level_path: String = "res://World/Tutorial.tscn"

const SAVE_DIR = "user://"

func save_game(slot: int):
	current_slot = slot
	
	# Wait for the end of the frame to capture screenshot safely
	await get_tree().process_frame
	var img = get_viewport().get_texture().get_image()
	img.save_png(SAVE_DIR + "save_slot_" + str(slot) + ".png")
	
	# Save data
	var data = {
		"level": current_level_path
	}
	var file = FileAccess.open(SAVE_DIR + "save_slot_" + str(slot) + ".json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

func load_game(slot: int):
	current_slot = slot
	var path = SAVE_DIR + "save_slot_" + str(slot) + ".json"
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		var text = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		if json.parse(text) == OK:
			var data = json.get_data()
			if data is Dictionary and data.has("level"):
				current_level_path = data["level"]
				get_tree().change_scene_to_file(current_level_path)
				return
				
	# Fallback if no save
	current_level_path = "res://World/Tutorial.tscn"
	get_tree().change_scene_to_file(current_level_path)

func delete_save(slot: int):
	var json_path = SAVE_DIR + "save_slot_" + str(slot) + ".json"
	var png_path = SAVE_DIR + "save_slot_" + str(slot) + ".png"
	
	if FileAccess.file_exists(json_path):
		DirAccess.remove_absolute(json_path)
	if FileAccess.file_exists(png_path):
		DirAccess.remove_absolute(png_path)

func reload_current_save():
	get_tree().change_scene_to_file(current_level_path)

func load_level(path: String):
	current_level_path = path
	get_tree().change_scene_to_file(path)
	# Auto-save when entering a new level
	save_game(current_slot)

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		# Immediately save when hitting the X button
		if current_level_path != "" and current_slot > 0:
			save_game(current_slot)
