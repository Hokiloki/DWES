extends Node2D
class_name FogOfWarSystem

## FogOfWarSystem - Manages layer-based fog of war with configurable exploration radius
## Layer 0: No fog, Layer 1: Fog with radius, Layer 2: Detail maps without fog

signal fog_updated(position: Vector2, radius: float)
signal area_explored(area_bounds: Rect2)

enum FogLayer {
	WORLD = 0, # No fog
	REGION = 1, # Fog with exploration radius
	LOCAL = 2 # Detail maps, no fog
}

@export var exploration_radius: float = 100.0
@export var trail_width: float = 20.0
@export var fog_color: Color = Color(0, 0, 0, 0.8)
@export var explored_color: Color = Color(0, 0, 0, 0.3)

var current_layer: FogLayer = FogLayer.REGION
var explored_areas: Dictionary = {} # Layer -> Array of explored areas
var fog_texture: ImageTexture
var fog_image: Image
var network_manager: NetworkManager
var game_manager: GameManager

# Group position tracking
var group_position: Vector2 = Vector2.ZERO
var group_trail: Array[Vector2] = []

func _ready():
	print("FogOfWarSystem initialized")
	network_manager = get_node("/root/NetworkManager")
	game_manager = get_node("/root/GameManager")

	_initialize_fog_layers()
	_setup_fog_texture()

func _initialize_fog_layers():
	for layer in FogLayer.values():
		explored_areas[layer] = []

func _setup_fog_texture():
	# Create fog texture for masking
	var world_size = Vector2(4096, 2048) # Should match MapSystem world_size
	fog_image = Image.create(int(world_size.x), int(world_size.y), false, Image.FORMAT_RGBA8)
	fog_image.fill(fog_color)

	fog_texture = ImageTexture.new()
	fog_texture.set_image(fog_image)

	print("Fog texture initialized: ", world_size)

func set_layer(new_layer: FogLayer):
	if current_layer != new_layer:
		current_layer = new_layer
		_update_fog_visibility()
		print("Fog layer changed to: ", FogLayer.keys()[new_layer])

func update_group_position(position: Vector2):
	if position.distance_to(group_position) > 10.0: # Minimum movement threshold
		group_position = position
		group_trail.append(position)

		# Limit trail length for performance
		if group_trail.size() > 1000:
			group_trail = group_trail.slice(500)

		if current_layer == FogLayer.REGION:
			_explore_area(position, exploration_radius)

			# Sync with network
			if network_manager:
				network_manager.sync_fog_update.rpc(position, exploration_radius)

func _explore_area(center: Vector2, radius: float):
	var area_rect = Rect2(
		center - Vector2(radius, radius),
		Vector2(radius * 2, radius * 2)
	)

	# Add to explored areas
	explored_areas[current_layer].append({
		"center": center,
		"radius": radius,
		"explored_at": Time.get_unix_time_from_system()
	})

	# Update fog texture
	_update_fog_texture(center, radius)

	area_explored.emit(area_rect)
	fog_updated.emit(center, radius)

	print("Area explored: ", center, " radius: ", radius)

func _update_fog_texture(center: Vector2, radius: float):
	if not fog_image:
		return

	var image_size = fog_image.get_size()
	var center_pixel = Vector2(
		int(center.x * image_size.x / 4096.0),
		int(center.y * image_size.y / 2048.0)
	)
	var radius_pixel = int(radius * image_size.x / 4096.0)

	# Clear circular area in fog
	for y in range(max(0, center_pixel.y - radius_pixel), min(image_size.y, center_pixel.y + radius_pixel)):
		for x in range(max(0, center_pixel.x - radius_pixel), min(image_size.x, center_pixel.x + radius_pixel)):
			var distance = Vector2(x, y).distance_to(center_pixel)
			if distance <= radius_pixel:
				var alpha = 1.0 - (distance / radius_pixel)
				fog_image.set_pixel(x, y, Color(0, 0, 0, explored_color.a * alpha))

	# Update trail
	_update_trail_in_texture()

	fog_texture.set_image(fog_image)

func _update_trail_in_texture():
	if group_trail.size() < 2:
		return

	var image_size = fog_image.get_size()
	var trail_width_pixel = int(trail_width * image_size.x / 4096.0)

	for i in range(1, group_trail.size()):
		var start = group_trail[i - 1]
		var end = group_trail[i]

		var start_pixel = Vector2(
			int(start.x * image_size.x / 4096.0),
			int(start.y * image_size.y / 2048.0)
		)
		var end_pixel = Vector2(
			int(end.x * image_size.x / 4096.0),
			int(end.y * image_size.y / 2048.0)
		)

		_draw_line_in_texture(start_pixel, end_pixel, trail_width_pixel)

func _draw_line_in_texture(start: Vector2, end: Vector2, width: int):
	var distance = start.distance_to(end)
	var steps = int(distance)

	if steps == 0:
		return

	var step_vector = (end - start) / steps

	for i in range(steps):
		var pos = start + step_vector * i
		_clear_circle_in_texture(pos, width / 2)

func _clear_circle_in_texture(center: Vector2, radius: int):
	var image_size = fog_image.get_size()

	for y in range(max(0, int(center.y) - radius), min(image_size.y, int(center.y) + radius)):
		for x in range(max(0, int(center.x) - radius), min(image_size.x, int(center.x) + radius)):
			var distance = Vector2(x, y).distance_to(center)
			if distance <= radius:
				fog_image.set_pixel(x, y, explored_color)

func _update_fog_visibility():
	visible = (current_layer == FogLayer.REGION)

func is_area_explored(position: Vector2, layer: FogLayer = FogLayer.REGION) -> bool:
	if layer == FogLayer.WORLD or layer == FogLayer.LOCAL:
		return true # No fog on these layers

	var areas = explored_areas.get(layer, [])
	for area in areas:
		var distance = position.distance_to(area.center)
		if distance <= area.radius:
			return true

	return false

func get_exploration_percentage(layer: FogLayer = FogLayer.REGION) -> float:
	if layer == FogLayer.WORLD or layer == FogLayer.LOCAL:
		return 100.0

	# Calculate rough exploration percentage
	var total_area = 4096.0 * 2048.0
	var explored_area = 0.0

	var areas = explored_areas.get(layer, [])
	for area in areas:
		explored_area += PI * area.radius * area.radius

	return min(100.0, (explored_area / total_area) * 100.0)

func clear_exploration(layer: FogLayer = FogLayer.REGION):
	explored_areas[layer] = []
	group_trail.clear()

	if layer == current_layer:
		_setup_fog_texture() # Reset fog texture

	print("Exploration cleared for layer: ", FogLayer.keys()[layer])

# Network event handlers
func on_fog_update_remote(position: Vector2, radius: float):
	if current_layer == FogLayer.REGION:
		_explore_area(position, radius)

func get_fog_texture() -> ImageTexture:
	return fog_texture

func set_exploration_radius(new_radius: float):
	exploration_radius = new_radius
	print("Exploration radius set to: ", new_radius)

func set_trail_width(new_width: float):
	trail_width = new_width
	print("Trail width set to: ", new_width)
