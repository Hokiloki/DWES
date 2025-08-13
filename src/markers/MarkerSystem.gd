extends Node2D
class_name MarkerSystem

## MarkerSystem - Handles multiplayer marker placement, movement, and synchronization
## Each player can place, move, and delete their own markers with real-time sync

signal marker_placed(marker_id: String, marker_data: Dictionary)
signal marker_moved(marker_id: String, new_position: Vector2)
signal marker_removed(marker_id: String)

var markers: Dictionary = {}
var network_manager: NetworkManager
var game_manager: GameManager

# Marker scene to instantiate
var marker_scene: PackedScene

func _ready():
	print("MarkerSystem initialized")
	network_manager = get_node("/root/NetworkManager")
	game_manager = get_node("/root/GameManager")

	# TODO: Load marker scene
	# marker_scene = preload("res://src/markers/Marker.tscn")

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT and Input.is_action_pressed("place_marker"):
			var world_pos = get_global_mouse_position()
			place_marker(world_pos)

func place_marker(position: Vector2, player_id: int = -1, marker_name: String = "") -> String:
	if player_id == -1:
		player_id = network_manager.get_local_player_id()

	# Validate position
	var map_system = get_node_or_null("/root/GameManager/MapSystem")
	if map_system and not map_system.is_position_valid(position):
		print("Cannot place marker at invalid position: ", position)
		return ""

	# Generate unique marker ID
	var marker_id = _generate_marker_id(player_id)

	# Get player info for marker color and name
	var player_info = game_manager.players.get(player_id, {})
	var player_color = player_info.get("color", Color.WHITE)
	var player_name = player_info.get("name", "Player " + str(player_id))

	if marker_name.is_empty():
		marker_name = "Marker " + str(markers.size() + 1)

	var marker_data = {
		"id": marker_id,
		"position": position,
		"player_id": player_id,
		"player_name": player_name,
		"name": marker_name,
		"color": player_color,
		"created_at": Time.get_unix_time_from_system()
	}

	# Create marker locally
	_create_marker_visual(marker_data)
	markers[marker_id] = marker_data

	# Sync with network
	if network_manager:
		network_manager.sync_marker_placed.rpc(marker_data)

	marker_placed.emit(marker_id, marker_data)
	print("Marker placed: ", marker_name, " at ", position)

	return marker_id

func move_marker(marker_id: String, new_position: Vector2) -> bool:
	if not marker_id in markers:
		print("Cannot move non-existent marker: ", marker_id)
		return false

	var marker_data = markers[marker_id]
	var local_player_id = network_manager.get_local_player_id()

	# Check ownership
	if marker_data.player_id != local_player_id and not network_manager.is_server():
		print("Cannot move marker owned by another player")
		return false

	# Validate new position
	var map_system = get_node_or_null("/root/GameManager/MapSystem")
	if map_system and not map_system.is_position_valid(new_position):
		print("Cannot move marker to invalid position: ", new_position)
		return false

	# Update marker position
	marker_data.position = new_position
	_update_marker_visual(marker_id, new_position)

	# Sync with network
	if network_manager:
		network_manager.sync_marker_moved.rpc(marker_id, new_position)

	marker_moved.emit(marker_id, new_position)
	print("Marker moved: ", marker_id, " to ", new_position)

	return true

func remove_marker(marker_id: String) -> bool:
	if not marker_id in markers:
		print("Cannot remove non-existent marker: ", marker_id)
		return false

	var marker_data = markers[marker_id]
	var local_player_id = network_manager.get_local_player_id()

	# Check ownership or host privileges
	if marker_data.player_id != local_player_id and not network_manager.is_server():
		print("Cannot remove marker owned by another player")
		return false

	# Remove marker
	_remove_marker_visual(marker_id)
	markers.erase(marker_id)

	# Sync with network
	if network_manager:
		network_manager.sync_marker_removed.rpc(marker_id)

	marker_removed.emit(marker_id)
	print("Marker removed: ", marker_id)

	return true

func get_marker(marker_id: String) -> Dictionary:
	return markers.get(marker_id, {})

func get_markers_by_player(player_id: int) -> Array:
	var player_markers = []
	for marker_data in markers.values():
		if marker_data.player_id == player_id:
			player_markers.append(marker_data)
	return player_markers

func get_all_markers() -> Dictionary:
	return markers.duplicate()

# Network event handlers
func on_marker_placed_remote(marker_data: Dictionary):
	var marker_id = marker_data.id
	if not marker_id in markers:
		_create_marker_visual(marker_data)
		markers[marker_id] = marker_data
		marker_placed.emit(marker_id, marker_data)

func on_marker_moved_remote(marker_id: String, new_position: Vector2):
	if marker_id in markers:
		markers[marker_id].position = new_position
		_update_marker_visual(marker_id, new_position)
		marker_moved.emit(marker_id, new_position)

func on_marker_removed_remote(marker_id: String):
	if marker_id in markers:
		_remove_marker_visual(marker_id)
		markers.erase(marker_id)
		marker_removed.emit(marker_id)

# Visual marker management
func _create_marker_visual(marker_data: Dictionary):
	# TODO: Create actual marker visual node
	print("Creating marker visual: ", marker_data.name, " at ", marker_data.position)

func _update_marker_visual(marker_id: String, new_position: Vector2):
	# TODO: Update marker visual position
	print("Updating marker visual: ", marker_id, " to ", new_position)

func _remove_marker_visual(marker_id: String):
	# TODO: Remove marker visual node
	print("Removing marker visual: ", marker_id)

func _generate_marker_id(player_id: int) -> String:
	var timestamp = Time.get_unix_time_from_system()
	return "marker_" + str(player_id) + "_" + str(timestamp)
