extends Node2D

## Main - Coordinates all DWES systems and handles UI interactions
## Entry point for the application that initializes and connects all subsystems

var game_manager: GameManager
var network_manager: NetworkManager
var map_system: MapSystem
var marker_system: MarkerSystem
var fog_system: FogOfWarSystem
var biome_system: BiomeSystem
var barrier_system: BarrierSystem
var save_system: SaveSystem

# UI References
var status_label: Label
var players_label: Label
var network_label: Label
var host_button: Button
var join_button: Button
var biome_toggle: CheckBox
var barrier_toggle: CheckBox

func _ready():
	print("DWES Main scene initializing...")

	# Get system references
	_get_system_references()
	_get_ui_references()
	_setup_connections()
	_setup_ui()

	# Initialize game
	game_manager.change_state(GameManager.GameState.LOADING)

	print("DWES Main scene initialized successfully")

func _get_system_references():
	game_manager = get_node("/root/GameManager")
	network_manager = get_node("/root/NetworkManager")
	map_system = $MapSystem
	marker_system = $MarkerSystem
	fog_system = $FogOfWarSystem
	biome_system = $BiomeSystem
	barrier_system = $BarrierSystem
	save_system = $SaveSystem

	# Store references in GameManager for easy access
	game_manager.map_system = map_system
	game_manager.marker_system = marker_system
	game_manager.fog_system = fog_system
	game_manager.biome_system = biome_system
	game_manager.save_system = save_system

func _get_ui_references():
	status_label = $UI/DebugPanel/StatusLabel
	players_label = $UI/DebugPanel/PlayersLabel
	network_label = $UI/DebugPanel/NetworkLabel
	host_button = $UI/DebugPanel/Controls/HostButton
	join_button = $UI/DebugPanel/Controls/JoinButton
	biome_toggle = $UI/DebugPanel/Controls/BiomeToggle
	barrier_toggle = $UI/DebugPanel/Controls/BarrierToggle

func _setup_connections():
	# Game Manager connections
	game_manager.game_state_changed.connect(_on_game_state_changed)
	game_manager.player_joined.connect(_on_player_joined)
	game_manager.player_left.connect(_on_player_left)

	# Network Manager connections
	network_manager.server_started.connect(_on_server_started)
	network_manager.server_stopped.connect(_on_server_stopped)
	network_manager.connection_failed.connect(_on_connection_failed)

	# Map System connections
	map_system.map_loaded.connect(_on_map_loaded)
	map_system.zoom_changed.connect(_on_zoom_changed)

	# Marker System connections
	marker_system.marker_placed.connect(_on_marker_placed)
	marker_system.marker_moved.connect(_on_marker_moved)
	marker_system.marker_removed.connect(_on_marker_removed)

	# Fog System connections
	fog_system.fog_updated.connect(_on_fog_updated)
	fog_system.area_explored.connect(_on_area_explored)

	# Biome System connections
	biome_system.biome_layer_toggled.connect(_on_biome_layer_toggled)
	biome_system.biome_data_loaded.connect(_on_biome_data_loaded)

	# Barrier System connections
	barrier_system.barrier_hit.connect(_on_barrier_hit)

	# Save System connections
	save_system.save_completed.connect(_on_save_completed)
	save_system.load_completed.connect(_on_load_completed)

func _setup_ui():
	# Connect UI signals
	host_button.pressed.connect(_on_host_button_pressed)
	join_button.pressed.connect(_on_join_button_pressed)
	biome_toggle.toggled.connect(_on_biome_toggle_toggled)
	barrier_toggle.toggled.connect(_on_barrier_toggle_toggled)

	# Update initial UI state
	_update_ui()

func _update_ui():
	# Update status
	var state_name = GameManager.GameState.keys()[game_manager.current_state]
	status_label.text = "DWES Status: " + state_name

	# Update player count
	players_label.text = "Players: " + str(game_manager.players.size())

	# Update network status
	if network_manager.is_host:
		network_label.text = "Network: Host (Port " + str(network_manager.server_port) + ")"
	elif network_manager.multiplayer.multiplayer_peer:
		network_label.text = "Network: Connected"
	else:
		network_label.text = "Network: Offline"

	# Update button states
	host_button.disabled = network_manager.multiplayer.multiplayer_peer != null
	join_button.disabled = network_manager.multiplayer.multiplayer_peer != null

# Game Manager event handlers
func _on_game_state_changed(new_state: GameManager.GameState):
	print("Game state changed to: ", GameManager.GameState.keys()[new_state])
	_update_ui()

	if new_state == GameManager.GameState.PLAYING:
		# Game is ready to play
		print("DWES is ready for gameplay!")

func _on_player_joined(_player_id: int, player_name: String):
	print("Player joined: ", player_name)
	_update_ui()

func _on_player_left(player_id: int):
	print("Player left: ", player_id)
	_update_ui()

# Network Manager event handlers
func _on_server_started():
	print("Server started successfully")
	_update_ui()

	# Create a default group save
	save_system.create_group_save("default_group", "Default Group")

	# Transition to playing state
	game_manager.change_state(GameManager.GameState.PLAYING)

func _on_server_stopped():
	print("Server stopped")
	_update_ui()

func _on_connection_failed():
	print("Failed to connect to server")
	_update_ui()

# Map System event handlers
func _on_map_loaded():
	print("Map loaded successfully")

func _on_zoom_changed(new_zoom: float):
	# Update fog system radius based on zoom
	var adjusted_radius = game_manager.config.fog_radius / new_zoom
	fog_system.set_exploration_radius(adjusted_radius)

# Marker System event handlers
func _on_marker_placed(_marker_id: String, marker_data: Dictionary):
	print("Marker placed: ", marker_data.name)

	# Log to session
	save_system.add_session_log_entry("Marker placed: " + marker_data.name + " at " + str(marker_data.position))

func _on_marker_moved(marker_id: String, new_position: Vector2):
	print("Marker moved: ", marker_id, " to ", new_position)

func _on_marker_removed(marker_id: String):
	print("Marker removed: ", marker_id)

# Fog System event handlers
func _on_fog_updated(position: Vector2, _radius: float):
	# Update group position for save system
	if save_system.group_data.has("group_position"):
		save_system.group_data.group_position = {"x": position.x, "y": position.y}

func _on_area_explored(area_bounds: Rect2):
	print("New area explored: ", area_bounds)

# Biome System event handlers
func _on_biome_layer_toggled(is_visible: bool):
	print("Biome layer visibility: ", is_visible)

func _on_biome_data_loaded():
	print("Biome data loaded")

# Barrier System event handlers
func _on_barrier_hit(hit_position: Vector2, barrier_id: String):
	var barrier_info = barrier_system.get_barrier_info(barrier_id)
	var description = barrier_info.get("description", "Blocked Area")
	print("Barrier hit: ", description, " at ", hit_position)

	# TODO: Show "Coming Soon" message to player

# Save System event handlers
func _on_save_completed(save_name: String):
	print("Save completed: ", save_name)

func _on_load_completed(save_name: String):
	print("Save loaded: ", save_name)

# UI event handlers
func _on_host_button_pressed():
	print("Starting host...")
	network_manager.start_host()

func _on_join_button_pressed():
	# TODO: Show join dialog for IP input
	print("Joining server...")
	network_manager.join_server("127.0.0.1")

func _on_biome_toggle_toggled(button_pressed: bool):
	biome_system.set_biome_visibility(button_pressed)

func _on_barrier_toggle_toggled(button_pressed: bool):
	barrier_system.set_barrier_visibility(button_pressed)

# Input handling
func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F1:
				# Toggle debug panel
				$UI/DebugPanel.visible = !$UI/DebugPanel.visible
			KEY_F5:
				# Quick save
				if network_manager.is_server() and not save_system.current_group_id.is_empty():
					save_system.save_group_data()
			KEY_B:
				# Toggle biomes
				biome_toggle.button_pressed = !biome_toggle.button_pressed
				_on_biome_toggle_toggled(biome_toggle.button_pressed)
			KEY_N:
				# Toggle barriers
				barrier_toggle.button_pressed = !barrier_toggle.button_pressed
				_on_barrier_toggle_toggled(barrier_toggle.button_pressed)

func _process(_delta):
	# Update fog system with current group position if needed
	if game_manager.current_state == GameManager.GameState.PLAYING:
		# For now, use mouse position as group position for testing
		var mouse_pos = get_global_mouse_position()
		fog_system.update_group_position(mouse_pos)
