extends Node

const SETTINGS_FILE = "user://settings.json"

var mouse_sensitivity: float = 0.0025
var fov: float = 75.0
var fullscreen: bool = false
var vsync: bool = true

var default_keybinds = {
	"move_forward": KEY_W,
	"move_backward": KEY_S,
	"move_left": KEY_A,
	"move_right": KEY_D,
	"jump": KEY_SPACE,
	"fire_lidar": MOUSE_BUTTON_LEFT
}

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	_init_input_map()
	load_settings()

func _init_input_map():
	for action in default_keybinds.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			var val = default_keybinds[action]
			var event
			if val == MOUSE_BUTTON_LEFT or val == MOUSE_BUTTON_RIGHT:
				event = InputEventMouseButton.new()
				event.button_index = val
			else:
				event = InputEventKey.new()
				event.physical_keycode = val
			InputMap.action_add_event(action, event)

func save_settings():
	var data = {
		"mouse_sensitivity": mouse_sensitivity,
		"fov": fov,
		"fullscreen": fullscreen,
		"vsync": vsync,
		"keybinds": {}
	}
	
	for action in default_keybinds.keys():
		if InputMap.has_action(action):
			var events = InputMap.action_get_events(action)
			if events.size() > 0:
				var ev = events[0]
				if ev is InputEventKey:
					data["keybinds"][action] = {"type": "key", "value": ev.physical_keycode}
				elif ev is InputEventMouseButton:
					data["keybinds"][action] = {"type": "mouse", "value": ev.button_index}
					
	var file = FileAccess.open(SETTINGS_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))

func load_settings():
	if FileAccess.file_exists(SETTINGS_FILE):
		var file = FileAccess.open(SETTINGS_FILE, FileAccess.READ)
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			var data = json.get_data()
			if data is Dictionary:
				if data.has("mouse_sensitivity"): mouse_sensitivity = data["mouse_sensitivity"]
				if data.has("fov"): fov = data["fov"]
				if data.has("fullscreen"): fullscreen = data["fullscreen"]
				if data.has("vsync"): vsync = data["vsync"]
				
				if data.has("keybinds"):
					for action in data["keybinds"]:
						if InputMap.has_action(action):
							InputMap.action_erase_events(action)
							var entry = data["keybinds"][action]
							var event
							if entry["type"] == "key":
								event = InputEventKey.new()
								event.physical_keycode = int(entry["value"])
							elif entry["type"] == "mouse":
								event = InputEventMouseButton.new()
								event.button_index = int(entry["value"])
							if event:
								InputMap.action_add_event(action, event)
	apply_graphics_settings()

func apply_graphics_settings():
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		
	if vsync:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

func remap_action(action: String, event: InputEvent):
	if InputMap.has_action(action):
		InputMap.action_erase_events(action)
		InputMap.action_add_event(action, event)
		save_settings()
