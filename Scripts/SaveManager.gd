extends Node

var current_slot: int = 1
var current_level_path: String = ""

# For jumpscare scene
var jumpscare_enemy_scene_file: String = ""

# Debug variable for fast testing:
# -1 = Disabled (Default)
# 0 = Tutorial, 1 = Room1, 2 = Room2, 3 = Finale
var DEBUG_START_ROOM: int = -1

const SAVE_DIR = "user://"
const GLOBAL_SAVE_PATH = "user://global_save.json"

var game_completed: bool = false

func _ready():
	_load_global()

func _load_global():
	if FileAccess.file_exists(GLOBAL_SAVE_PATH):
		var file = FileAccess.open(GLOBAL_SAVE_PATH, FileAccess.READ)
		var text = file.get_as_text()
		file.close()
		var json = JSON.new()
		if json.parse(text) == OK:
			var data = json.get_data()
			if data is Dictionary and data.has("game_completed"):
				game_completed = data["game_completed"]

func mark_game_completed():
	game_completed = true
	var data = {
		"game_completed": true
	}
	var file = FileAccess.open(GLOBAL_SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

func save_game(slot: int):
	current_slot = slot
	
	# Wait for the end of the frame to capture screenshot safely
	await get_tree().process_frame
	var img = get_viewport().get_texture().get_image()
	img.save_png(SAVE_DIR + "save_slot_" + str(slot) + ".png")
	
	var data = {
		"level": current_level_path
	}
	var path = SAVE_DIR + "save_slot_" + str(slot) + ".json"
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

func load_game(slot: int):
	current_slot = slot
	
	if DEBUG_START_ROOM != -1:
		var rooms = [
			"res://World/Tutorial.tscn",
			"res://World/Room1.tscn",
			"res://World/Room2.tscn",
			"res://World/Finale.tscn"
		]
		if DEBUG_START_ROOM >= 0 and DEBUG_START_ROOM < rooms.size():
			current_level_path = rooms[DEBUG_START_ROOM]
			get_tree().change_scene_to_file(current_level_path)
			return
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
	current_level_path = "res://Menu/IntroCutscene.tscn"
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
