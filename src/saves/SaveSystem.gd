extends Node
class_name SaveSystem

## SaveSystem - Manages group-based world saves with delta storage
## Central base world + group-specific files for markers, fog status, and POIs

signal save_completed(save_name: String)
signal load_completed(save_name: String)
signal save_failed(save_name: String, error: String)
signal load_failed(save_name: String, error: String)

const SAVE_DIRECTORY = "user://saves/"
const BASE_WORLD_FILE = "base_world.dwes"
const GROUP_SAVE_EXTENSION = ".group"

var current_group_id: String = ""
var base_world_data: Dictionary = {}
var group_data: Dictionary = {}
var auto_save_enabled: bool = true
var auto_save_interval: float = 300.0 # 5 minutes

var auto_save_timer: Timer
var game_manager: GameManager
var network_manager: NetworkManager

func _ready():
	print("SaveSystem initialized")
	game_manager = get_node("/root/GameManager")
	network_manager = get_node("/root/NetworkManager")

	_ensure_save_directory()
	_setup_auto_save()
	_load_base_world()

func _ensure_save_directory():
	if not DirAccess.dir_exists_absolute(SAVE_DIRECTORY):
		DirAccess.open("user://").make_dir_recursive("saves")
		print("Created save directory: ", SAVE_DIRECTORY)

func _setup_auto_save():
	auto_save_timer = Timer.new()
	auto_save_timer.wait_time = auto_save_interval
	auto_save_timer.timeout.connect(_on_auto_save_timeout)
	add_child(auto_save_timer)

	if auto_save_enabled:
		auto_save_timer.start()

func _load_base_world():
	var base_world_path = SAVE_DIRECTORY + BASE_WORLD_FILE

	if FileAccess.file_exists(base_world_path):
		var file = FileAccess.open(base_world_path, FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			file.close()

			var json = JSON.new()
			var parse_result = json.parse(json_string)

			if parse_result == OK:
				base_world_data = json.data
				print("Base world loaded successfully")
			else:
				print("Failed to parse base world data: ", json.get_error_message())
	else:
		print("No base world file found, creating default")
		_create_default_base_world()

func _create_default_base_world():
	base_world_data = {
		"version": "1.0",
		"world_size": {"x": 4096, "y": 2048},
		"created_at": Time.get_unix_time_from_system(),
		"pois": [],
		"barriers": [],
		"biome_config": {},
		"metadata": {
			"name": "Kantaraya World",
			"description": "Base world for DWES"
		}
	}

	save_base_world()

func save_base_world() -> bool:
	var base_world_path = SAVE_DIRECTORY + BASE_WORLD_FILE
	var file = FileAccess.open(base_world_path, FileAccess.WRITE)

	if not file:
		print("Failed to open base world file for writing")
		return false

	var json_string = JSON.stringify(base_world_data)
	file.store_string(json_string)
	file.close()

	print("Base world saved successfully")
	return true

func create_group_save(group_id: String, group_name: String = "") -> bool:
	if group_id.is_empty():
		print("Cannot create group save with empty ID")
		return false

	current_group_id = group_id

	group_data = {
		"version": "1.0",
		"group_id": group_id,
		"group_name": group_name if not group_name.is_empty() else "Group " + group_id,
		"created_at": Time.get_unix_time_from_system(),
		"last_saved": Time.get_unix_time_from_system(),
		"markers": {},
		"fog_exploration": {},
		"discovered_pois": [],
		"group_position": {"x": 0, "y": 0},
		"session_log": []
	}

	return save_group_data()

func save_group_data() -> bool:
	if current_group_id.is_empty():
		print("No group ID set for saving")
		return false

	# Collect current game state
	_collect_game_state()

	var group_file_path = SAVE_DIRECTORY + current_group_id + GROUP_SAVE_EXTENSION
	var file = FileAccess.open(group_file_path, FileAccess.WRITE)

	if not file:
		print("Failed to open group save file for writing: ", group_file_path)
		save_failed.emit(current_group_id, "Could not open file for writing")
		return false

	group_data.last_saved = Time.get_unix_time_from_system()
	var json_string = JSON.stringify(group_data)
	file.store_string(json_string)
	file.close()

	save_completed.emit(current_group_id)
	print("Group save completed: ", current_group_id)
	return true

func load_group_data(group_id: String) -> bool:
	if group_id.is_empty():
		print("Cannot load group with empty ID")
		return false

	var group_file_path = SAVE_DIRECTORY + group_id + GROUP_SAVE_EXTENSION

	if not FileAccess.file_exists(group_file_path):
		print("Group save file not found: ", group_file_path)
		load_failed.emit(group_id, "Save file not found")
		return false

	var file = FileAccess.open(group_file_path, FileAccess.READ)
	if not file:
		print("Failed to open group save file: ", group_file_path)
		load_failed.emit(group_id, "Could not open save file")
		return false

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_string)

	if parse_result != OK:
		print("Failed to parse group save data: ", json.get_error_message())
		load_failed.emit(group_id, "Invalid save file format")
		return false

	group_data = json.data
	current_group_id = group_id

	# Apply loaded state to game systems
	_apply_game_state()

	load_completed.emit(group_id)
	print("Group save loaded: ", group_id)
	return true

func _collect_game_state():
	# Collect markers
	var marker_system = get_node_or_null("/root/GameManager/MarkerSystem")
	if marker_system:
		group_data.markers = marker_system.get_all_markers()

	# Collect fog exploration
	var fog_system = get_node_or_null("/root/GameManager/FogOfWarSystem")
	if fog_system:
		group_data.fog_exploration = {
			"explored_areas": fog_system.explored_areas,
			"group_position": fog_system.group_position,
			"group_trail": fog_system.group_trail
		}

	# Collect discovered POIs
	# TODO: Implement POI discovery system

	print("Game state collected for save")

func _apply_game_state():
	# Apply markers
	var marker_system = get_node_or_null("/root/GameManager/MarkerSystem")
	if marker_system and group_data.has("markers"):
		# Clear existing markers and load saved ones
		for marker_data in group_data.markers.values():
			marker_system.on_marker_placed_remote(marker_data)

	# Apply fog exploration
	var fog_system = get_node_or_null("/root/GameManager/FogOfWarSystem")
	if fog_system and group_data.has("fog_exploration"):
		var fog_data = group_data.fog_exploration
		fog_system.explored_areas = fog_data.get("explored_areas", {})
		fog_system.group_position = Vector2(fog_data.get("group_position", {"x": 0, "y": 0}).x, fog_data.get("group_position", {"x": 0, "y": 0}).y)
		fog_system.group_trail = fog_data.get("group_trail", [])

	print("Game state applied from save")

func get_available_group_saves() -> Array:
	var saves = []
	var dir = DirAccess.open(SAVE_DIRECTORY)

	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()

		while file_name != "":
			if file_name.ends_with(GROUP_SAVE_EXTENSION):
				var group_id = file_name.get_basename()
				var save_info = _get_save_info(group_id)
				if not save_info.is_empty():
					saves.append(save_info)
			file_name = dir.get_next()

	return saves

func _get_save_info(group_id: String) -> Dictionary:
	var group_file_path = SAVE_DIRECTORY + group_id + GROUP_SAVE_EXTENSION
	var file = FileAccess.open(group_file_path, FileAccess.READ)

	if not file:
		return {}

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_string)

	if parse_result != OK:
		return {}

	var data = json.data
	return {
		"group_id": group_id,
		"group_name": data.get("group_name", "Unknown"),
		"created_at": data.get("created_at", 0),
		"last_saved": data.get("last_saved", 0),
		"marker_count": data.get("markers", {}).size()
	}

func delete_group_save(group_id: String) -> bool:
	var group_file_path = SAVE_DIRECTORY + group_id + GROUP_SAVE_EXTENSION

	if FileAccess.file_exists(group_file_path):
		DirAccess.open(SAVE_DIRECTORY).remove(group_id + GROUP_SAVE_EXTENSION)
		print("Group save deleted: ", group_id)
		return true

	return false

func set_auto_save(enabled: bool, interval: float = 300.0):
	auto_save_enabled = enabled
	auto_save_interval = interval

	if auto_save_timer:
		auto_save_timer.wait_time = interval

		if enabled:
			auto_save_timer.start()
		else:
			auto_save_timer.stop()

	print("Auto-save ", "enabled" if enabled else "disabled", " (interval: ", interval, "s)")

func _on_auto_save_timeout():
	if not current_group_id.is_empty() and network_manager.is_server():
		print("Auto-saving...")
		save_group_data()

func get_current_group_id() -> String:
	return current_group_id

func get_group_data() -> Dictionary:
	return group_data.duplicate()

func add_session_log_entry(entry: String):
	if group_data.has("session_log"):
		group_data.session_log.append({
			"timestamp": Time.get_unix_time_from_system(),
			"entry": entry
		})

		# Limit log size
		if group_data.session_log.size() > 1000:
			group_data.session_log = group_data.session_log.slice(500)
