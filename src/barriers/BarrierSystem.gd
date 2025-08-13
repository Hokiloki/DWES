extends Node2D
class_name BarrierSystem

## BarrierSystem - Manages hard gates and blocked areas using walkability masks
## Prevents players from entering locked zones with "Coming Soon" visual overlay

signal barrier_added(barrier_id: String)
signal barrier_removed(barrier_id: String)
signal barrier_hit(position: Vector2, barrier_id: String)

@export var barrier_color: Color = Color.RED
@export var barrier_opacity: float = 0.5
@export var coming_soon_text: String = "Coming Soon"

var barriers: Dictionary = {}
var walkability_mask: Image
var barrier_texture: ImageTexture
var barrier_image: Image

func _ready():
	print("BarrierSystem initialized")
	_setup_walkability_mask()
	_setup_barrier_texture()

func _setup_walkability_mask():
	# Create walkability mask (1-bit: 1 = walkable, 0 = blocked)
	var world_size = Vector2(4096, 2048) # Should match MapSystem world_size
	walkability_mask = Image.create(int(world_size.x), int(world_size.y), false, Image.FORMAT_L8)
	walkability_mask.fill(Color.WHITE) # Default: all areas walkable

	# TODO: Load actual walkability mask from project owner assets
	_create_placeholder_barriers()

	print("Walkability mask initialized: ", world_size)

func _setup_barrier_texture():
	# Create visual overlay for barriers
	var world_size = Vector2(4096, 2048)
	barrier_image = Image.create(int(world_size.x), int(world_size.y), false, Image.FORMAT_RGBA8)
	barrier_image.fill(Color.TRANSPARENT)

	barrier_texture = ImageTexture.new()
	barrier_texture.set_image(barrier_image)

	print("Barrier texture initialized")

func _create_placeholder_barriers():
	# Create some placeholder blocked areas for testing
	var image_size = walkability_mask.get_size()

	# Create a few blocked rectangular areas
	for i in range(5):
		var rect_pos = Vector2(
			randf() * image_size.x * 0.8,
			randf() * image_size.y * 0.8
		)
		var rect_size = Vector2(
			randf_range(100, 300),
			randf_range(100, 300)
		)

		var barrier_id = "placeholder_" + str(i)
		add_rectangular_barrier(barrier_id, rect_pos, rect_size, "Placeholder Blocked Area")

func add_rectangular_barrier(barrier_id: String, position: Vector2, size: Vector2, description: String = "") -> bool:
	if barrier_id in barriers:
		print("Barrier already exists: ", barrier_id)
		return false

	var barrier_data = {
		"id": barrier_id,
		"type": "rectangular",
		"position": position,
		"size": size,
		"description": description,
		"created_at": Time.get_unix_time_from_system()
	}

	barriers[barrier_id] = barrier_data
	_apply_rectangular_barrier(position, size)
	_draw_barrier_overlay(position, size)

	barrier_added.emit(barrier_id)
	print("Rectangular barrier added: ", barrier_id, " at ", position)
	return true

func add_circular_barrier(barrier_id: String, center: Vector2, radius: float, description: String = "") -> bool:
	if barrier_id in barriers:
		print("Barrier already exists: ", barrier_id)
		return false

	var barrier_data = {
		"id": barrier_id,
		"type": "circular",
		"center": center,
		"radius": radius,
		"description": description,
		"created_at": Time.get_unix_time_from_system()
	}

	barriers[barrier_id] = barrier_data
	_apply_circular_barrier(center, radius)
	_draw_circular_barrier_overlay(center, radius)

	barrier_added.emit(barrier_id)
	print("Circular barrier added: ", barrier_id, " at ", center)
	return true

func remove_barrier(barrier_id: String) -> bool:
	if not barrier_id in barriers:
		print("Barrier not found: ", barrier_id)
		return false

	var barrier_data = barriers[barrier_id]

	# Remove from walkability mask (set to walkable)
	if barrier_data.type == "rectangular":
		_remove_rectangular_barrier(barrier_data.position, barrier_data.size)
	elif barrier_data.type == "circular":
		_remove_circular_barrier(barrier_data.center, barrier_data.radius)

	barriers.erase(barrier_id)
	_update_barrier_texture()

	barrier_removed.emit(barrier_id)
	print("Barrier removed: ", barrier_id)
	return true

func _apply_rectangular_barrier(position: Vector2, size: Vector2):
	var image_size = walkability_mask.get_size()
	var start_x = max(0, int(position.x))
	var start_y = max(0, int(position.y))
	var end_x = min(image_size.x, int(position.x + size.x))
	var end_y = min(image_size.y, int(position.y + size.y))

	for y in range(start_y, end_y):
		for x in range(start_x, end_x):
			walkability_mask.set_pixel(x, y, Color.BLACK) # 0 = blocked

func _apply_circular_barrier(center: Vector2, radius: float):
	var image_size = walkability_mask.get_size()
	var start_x = max(0, int(center.x - radius))
	var start_y = max(0, int(center.y - radius))
	var end_x = min(image_size.x, int(center.x + radius))
	var end_y = min(image_size.y, int(center.y + radius))

	for y in range(start_y, end_y):
		for x in range(start_x, end_x):
			var distance = Vector2(x, y).distance_to(center)
			if distance <= radius:
				walkability_mask.set_pixel(x, y, Color.BLACK) # 0 = blocked

func _remove_rectangular_barrier(position: Vector2, size: Vector2):
	var image_size = walkability_mask.get_size()
	var start_x = max(0, int(position.x))
	var start_y = max(0, int(position.y))
	var end_x = min(image_size.x, int(position.x + size.x))
	var end_y = min(image_size.y, int(position.y + size.y))

	for y in range(start_y, end_y):
		for x in range(start_x, end_x):
			walkability_mask.set_pixel(x, y, Color.WHITE) # 1 = walkable

func _remove_circular_barrier(center: Vector2, radius: float):
	var image_size = walkability_mask.get_size()
	var start_x = max(0, int(center.x - radius))
	var start_y = max(0, int(center.y - radius))
	var end_x = min(image_size.x, int(center.x + radius))
	var end_y = min(image_size.y, int(center.y + radius))

	for y in range(start_y, end_y):
		for x in range(start_x, end_x):
			var distance = Vector2(x, y).distance_to(center)
			if distance <= radius:
				walkability_mask.set_pixel(x, y, Color.WHITE) # 1 = walkable

func _draw_barrier_overlay(position: Vector2, size: Vector2):
	var image_size = barrier_image.get_size()
	var start_x = max(0, int(position.x))
	var start_y = max(0, int(position.y))
	var end_x = min(image_size.x, int(position.x + size.x))
	var end_y = min(image_size.y, int(position.y + size.y))

	var overlay_color = Color(barrier_color.r, barrier_color.g, barrier_color.b, barrier_opacity)

	for y in range(start_y, end_y):
		for x in range(start_x, end_x):
			barrier_image.set_pixel(x, y, overlay_color)

func _draw_circular_barrier_overlay(center: Vector2, radius: float):
	var image_size = barrier_image.get_size()
	var start_x = max(0, int(center.x - radius))
	var start_y = max(0, int(center.y - radius))
	var end_x = min(image_size.x, int(center.x + radius))
	var end_y = min(image_size.y, int(center.y + radius))

	var overlay_color = Color(barrier_color.r, barrier_color.g, barrier_color.b, barrier_opacity)

	for y in range(start_y, end_y):
		for x in range(start_x, end_x):
			var distance = Vector2(x, y).distance_to(center)
			if distance <= radius:
				var alpha = barrier_opacity * (1.0 - distance / radius * 0.3)
				barrier_image.set_pixel(x, y, Color(barrier_color.r, barrier_color.g, barrier_color.b, alpha))

func _update_barrier_texture():
	# Rebuild barrier texture from current barriers
	barrier_image.fill(Color.TRANSPARENT)

	for barrier_data in barriers.values():
		if barrier_data.type == "rectangular":
			_draw_barrier_overlay(barrier_data.position, barrier_data.size)
		elif barrier_data.type == "circular":
			_draw_circular_barrier_overlay(barrier_data.center, barrier_data.radius)

	barrier_texture.set_image(barrier_image)

func is_position_walkable(world_pos: Vector2) -> bool:
	if not walkability_mask:
		return true # Default to walkable if no mask

	var image_size = walkability_mask.get_size()
	var pixel_pos = Vector2(
		clamp(int(world_pos.x), 0, image_size.x - 1),
		clamp(int(world_pos.y), 0, image_size.y - 1)
	)

	var pixel_color = walkability_mask.get_pixel(int(pixel_pos.x), int(pixel_pos.y))
	return pixel_color.r > 0.5 # White = walkable, Black = blocked

func check_movement_allowed(from: Vector2, to: Vector2) -> bool:
	# Check if movement from one position to another crosses any barriers
	var steps = int(from.distance_to(to))
	if steps == 0:
		return is_position_walkable(to)

	var step_vector = (to - from) / steps

	for i in range(steps + 1):
		var check_pos = from + step_vector * i
		if not is_position_walkable(check_pos):
			# Find which barrier was hit
			var barrier_id = get_barrier_at_position(check_pos)
			if not barrier_id.is_empty():
				barrier_hit.emit(check_pos, barrier_id)
			return false

	return true

func get_barrier_at_position(world_pos: Vector2) -> String:
	for barrier_id in barriers.keys():
		var barrier_data = barriers[barrier_id]

		if barrier_data.type == "rectangular":
			var pos = barrier_data.position
			var size = barrier_data.size
			if world_pos.x >= pos.x and world_pos.x <= pos.x + size.x and world_pos.y >= pos.y and world_pos.y <= pos.y + size.y:
				return barrier_id
		elif barrier_data.type == "circular":
			var distance = world_pos.distance_to(barrier_data.center)
			if distance <= barrier_data.radius:
				return barrier_id

	return ""

func get_barrier_info(barrier_id: String) -> Dictionary:
	return barriers.get(barrier_id, {})

func get_all_barriers() -> Dictionary:
	return barriers.duplicate()

func load_walkability_mask_from_file(file_path: String) -> bool:
	# TODO: Load walkability mask from project owner assets
	print("Loading walkability mask from: ", file_path)
	return false

func get_barrier_texture() -> ImageTexture:
	return barrier_texture

func set_barrier_visibility(visible: bool):
	self.visible = visible
	print("Barrier visibility set to: ", visible)

func get_walkability_mask() -> Image:
	return walkability_mask
