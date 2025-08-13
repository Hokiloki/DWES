extends Node

## NetworkManager - Handles multiplayer networking using Godot's High-Level Multiplayer API
## Manages host/client connections, player synchronization, and RPC calls

signal player_connected(player_id: int, player_info: Dictionary)
signal player_disconnected(player_id: int)
signal connection_failed()
signal server_started()
signal server_stopped()

const DEFAULT_PORT = 7000
const MAX_PLAYERS = 8

var is_host: bool = false
var server_port: int = DEFAULT_PORT
var connected_players: Dictionary = {}

func _ready():
	print("DWES NetworkManager initialized")
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func start_host(port: int = DEFAULT_PORT) -> bool:
	print("Starting host on port: ", port)

	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, MAX_PLAYERS)

	if error != OK:
		print("Failed to start server: ", error)
		return false

	multiplayer.multiplayer_peer = peer
	is_host = true
	server_port = port

	# Add host as player 1
	var host_info = {
		"name": "Host",
		"is_host": true
	}
	connected_players[1] = host_info
	player_connected.emit(1, host_info)

	server_started.emit()
	print("Host started successfully on port: ", port)
	return true

func join_server(address: String, port: int = DEFAULT_PORT) -> bool:
	print("Connecting to server: ", address, ":", port)

	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(address, port)

	if error != OK:
		print("Failed to create client: ", error)
		return false

	multiplayer.multiplayer_peer = peer
	is_host = false

	print("Attempting to connect to server...")
	return true

func stop_networking():
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null

	connected_players.clear()
	is_host = false

	if is_host:
		server_stopped.emit()

	print("Networking stopped")

func get_local_player_id() -> int:
	return multiplayer.get_unique_id()

func is_server() -> bool:
	return multiplayer.is_server()

# RPC calls for game synchronization
@rpc("any_peer", "call_local", "reliable")
func sync_marker_placed(marker_data: Dictionary):
	# Forward to marker system
	var marker_system = get_node_or_null("/root/GameManager/MarkerSystem")
	if marker_system:
		marker_system.on_marker_placed_remote(marker_data)

@rpc("any_peer", "call_local", "reliable")
func sync_marker_moved(marker_id: String, new_position: Vector2):
	var marker_system = get_node_or_null("/root/GameManager/MarkerSystem")
	if marker_system:
		marker_system.on_marker_moved_remote(marker_id, new_position)

@rpc("any_peer", "call_local", "reliable")
func sync_marker_removed(marker_id: String):
	var marker_system = get_node_or_null("/root/GameManager/MarkerSystem")
	if marker_system:
		marker_system.on_marker_removed_remote(marker_id)

@rpc("any_peer", "call_local", "reliable")
func sync_fog_update(position: Vector2, radius: float):
	var fog_system = get_node_or_null("/root/GameManager/FogOfWarSystem")
	if fog_system:
		fog_system.on_fog_update_remote(position, radius)

@rpc("any_peer", "call_local", "reliable")
func register_player(player_info: Dictionary):
	var sender_id = multiplayer.get_remote_sender_id()
	connected_players[sender_id] = player_info
	player_connected.emit(sender_id, player_info)
	print("Player registered: ", player_info.get("name", "Unknown"), " (ID: ", sender_id, ")")

# Network event handlers
func _on_peer_connected(id: int):
	print("Peer connected: ", id)

	if is_host:
		# Send current game state to new player
		_send_game_state_to_player(id)

func _on_peer_disconnected(id: int):
	print("Peer disconnected: ", id)

	if id in connected_players:
		connected_players.erase(id)
		player_disconnected.emit(id)

func _on_connected_to_server():
	print("Successfully connected to server")

	# Register this client with the server
	var player_info = {
		"name": "Player " + str(get_local_player_id()),
		"is_host": false
	}
	register_player.rpc(player_info)

func _on_connection_failed():
	print("Failed to connect to server")
	connection_failed.emit()

func _on_server_disconnected():
	print("Disconnected from server")
	stop_networking()

func _send_game_state_to_player(player_id: int):
	# TODO: Send current markers, fog state, etc. to new player
	print("Sending game state to player: ", player_id)

func validate_action(action: String, data: Dictionary) -> bool:
	# Host validates all multiplayer actions for security
	if not is_host:
		return true  # Clients don't validate

	# TODO: Implement action validation logic
	# Examples:
	# - Check if player can place marker at position
	# - Validate marker ownership for moves/deletions
	# - Check fog of war rules

	return true
