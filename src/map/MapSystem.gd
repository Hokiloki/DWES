extends Node2D
class_name MapSystem

## MapSystem - Handles world map display, zoom, pan, and chunk loading
## Manages the tilemap-based world representation with efficient rendering

signal map_loaded()
signal chunk_loaded(chunk_id: String)
signal zoom_changed(new_zoom: float)

@export var world_size: Vector2 = Vector2(4096, 2048)
@export var chunk_size: int = 512
@export var max_zoom: float = 5.0
@export var min_zoom: float = 0.1
@export var pan_speed: float = 500.0

var current_zoom: float = 1.0
var camera: Camera2D
var tilemap: TileMap
var loaded_chunks: Dictionary = {}
var world_texture: Texture2D

func _ready():
	print("MapSystem initialized")
	_setup_camera()
	_setup_tilemap()
	_load_world_data()

func _setup_camera():
	camera = Camera2D.new()
	camera.enabled = true
	add_child(camera)
	print("Camera setup complete")

func _setup_tilemap():
	tilemap = TileMap.new()
	add_child(tilemap)
	print("TileMap setup complete")

func _load_world_data():
	# TODO: Load world texture and data from assets
	print("Loading world data...")
	# Placeholder: Load from res://assets/world_map.png
	map_loaded.emit()

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_in()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_out()

	elif event is InputEventMouseMotion:
		if Input.is_action_pressed("pan_camera"):
			pan_camera(event.relative)

func zoom_in():
	set_zoom(current_zoom * 1.2)

func zoom_out():
	set_zoom(current_zoom / 1.2)

func set_zoom(new_zoom: float):
	new_zoom = clamp(new_zoom, min_zoom, max_zoom)
	if new_zoom != current_zoom:
		current_zoom = new_zoom
		camera.zoom = Vector2(current_zoom, current_zoom)
		zoom_changed.emit(current_zoom)
		_update_chunk_loading()

func pan_camera(delta: Vector2):
	camera.global_position -= delta / current_zoom

func _update_chunk_loading():
	# TODO: Implement chunk-based loading for performance
	var camera_pos = camera.global_position
	var visible_chunks = _get_visible_chunks(camera_pos)

	for chunk_id in visible_chunks:
		if not chunk_id in loaded_chunks:
			_load_chunk(chunk_id)

func _get_visible_chunks(center_pos: Vector2) -> Array:
	# Calculate which chunks are visible based on camera position and zoom
	var chunks = []
	# TODO: Implement chunk visibility calculation
	return chunks

func _load_chunk(chunk_id: String):
	# TODO: Load specific chunk data
	loaded_chunks[chunk_id] = true
	chunk_loaded.emit(chunk_id)
	print("Chunk loaded: ", chunk_id)

func world_to_screen(world_pos: Vector2) -> Vector2:
	return camera.to_screen_coordinate_from_global(world_pos)

func screen_to_world(screen_pos: Vector2) -> Vector2:
	return camera.get_global_mouse_position()

func is_position_valid(world_pos: Vector2) -> bool:
	# Check if position is within world bounds and walkable
	if world_pos.x < 0 or world_pos.x > world_size.x:
		return false
	if world_pos.y < 0 or world_pos.y > world_size.y:
		return false

	# TODO: Check walkability mask
	return true

func get_camera_position() -> Vector2:
	return camera.global_position

func set_camera_position(pos: Vector2):
	camera.global_position = pos
