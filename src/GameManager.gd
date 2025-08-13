extends Node

## GameManager - Central game state and configuration management
## Handles global game settings, player data, and coordinates between systems

signal game_state_changed(new_state: GameState)
signal player_joined(player_id: int, player_name: String)
signal player_left(player_id: int)

enum GameState {
	MENU,
	LOADING,
	PLAYING,
	PAUSED
}

# Game Configuration
@export var config: GameConfig = GameConfig.new()
var current_state: GameState = GameState.MENU
var players: Dictionary = {}
var local_player_id: int = -1

# Core Systems References
var network_manager: NetworkManager
var map_system: MapSystem
var marker_system: MarkerSystem
var fog_system: FogOfWarSystem
var biome_system: BiomeSystem
var save_system: SaveSystem

func _ready():
	print("DWES GameManager initialized")
	network_manager = get_node("/root/NetworkManager")
	_setup_connections()
	_load_config()

func _setup_connections():
	# Connect to network events
	if network_manager:
		network_manager.player_connected.connect(_on_player_connected)
		network_manager.player_disconnected.connect(_on_player_disconnected)

func _load_config():
	# TODO: Load configuration from file or create default
	print("Loading game configuration...")

func change_state(new_state: GameState):
	if current_state != new_state:
		var old_state = current_state
		current_state = new_state
		print("Game state changed: ", GameState.keys()[old_state], " -> ", GameState.keys()[new_state])
		game_state_changed.emit(new_state)

func add_player(player_id: int, player_name: String):
	players[player_id] = {
		"name": player_name,
		"color": _get_player_color(player_id),
		"connected_at": Time.get_unix_time_from_system()
	}
	player_joined.emit(player_id, player_name)
	print("Player added: ", player_name, " (ID: ", player_id, ")")

func remove_player(player_id: int):
	if player_id in players:
		var player_name = players[player_id]["name"]
		players.erase(player_id)
		player_left.emit(player_id)
		print("Player removed: ", player_name, " (ID: ", player_id, ")")

func _get_player_color(player_id: int) -> Color:
	# Assign distinct colors to players
	var colors = [
		Color.RED,
		Color.BLUE,
		Color.GREEN,
		Color.YELLOW,
		Color.MAGENTA,
		Color.CYAN,
		Color.ORANGE,
		Color.PURPLE
	]
	return colors[player_id % colors.size()]

func _on_player_connected(player_id: int, player_info: Dictionary):
	add_player(player_id, player_info.get("name", "Player " + str(player_id)))

func _on_player_disconnected(player_id: int):
	remove_player(player_id)
