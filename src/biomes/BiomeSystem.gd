extends Node2D
class_name BiomeSystem

## BiomeSystem - Manages biome layers with color-coded visualization
## Handles 6-10 basic biomes with toggle visibility

signal biome_layer_toggled(visible: bool)
signal biome_data_loaded()

@export var biomes_visible: bool = true
@export var biome_opacity: float = 0.7

var biome_data: Dictionary = {}
var biome_texture: ImageTexture
var biome_image: Image
var biome_colors: Dictionary = {}

# Default biome definitions
var default_biomes = {
	"grassland": {"color": Color.GREEN, "name": "Grassland"},
	"forest": {"color": Color.DARK_GREEN, "name": "Forest"},
	"desert": {"color": Color.YELLOW, "name": "Desert"},
	"mountain": {"color": Color.GRAY, "name": "Mountain"},
	"water": {"color": Color.BLUE, "name": "Water"},
	"swamp": {"color": Color.DARK_OLIVE_GREEN, "name": "Swamp"},
	"tundra": {"color": Color.CYAN, "name": "Tundra"},
	"volcanic": {"color": Color.RED, "name": "Volcanic"},
	"coastal": {"color": Color.LIGHT_BLUE, "name": "Coastal"},
	"badlands": {"color": Color.BROWN, "name": "Badlands"}
}

func _ready():
	print("BiomeSystem initialized")
	_load_biome_data()
	_setup_biome_texture()

func _load_biome_data():
	# TODO: Load biome data from project owner assets
	# For now, use default biomes
	biome_colors = default_biomes.duplicate()
	biome_data_loaded.emit()
	print("Biome data loaded: ", biome_colors.size(), " biomes")

func _setup_biome_texture():
	# Create biome texture overlay
	var world_size = Vector2(4096, 2048) # Should match MapSystem world_size
	biome_image = Image.create(int(world_size.x), int(world_size.y), false, Image.FORMAT_RGBA8)
	biome_image.fill(Color.TRANSPARENT)

	# TODO: Load actual biome map data and apply colors
	_generate_placeholder_biomes()

	biome_texture = ImageTexture.new()
	biome_texture.set_image(biome_image)

	print("Biome texture initialized: ", world_size)

func _generate_placeholder_biomes():
	# Generate some placeholder biome areas for testing
	var image_size = biome_image.get_size()
	var biome_keys = biome_colors.keys()

	# Create some random biome patches
	for i in range(20):
		var center = Vector2(
			randf() * image_size.x,
			randf() * image_size.y
		)
		var radius = randf_range(50, 200)
		var biome_key = biome_keys[randi() % biome_keys.size()]
		var biome_color = biome_colors[biome_key].color
		biome_color.a = biome_opacity

		_draw_biome_area(center, radius, biome_color)

func _draw_biome_area(center: Vector2, radius: float, color: Color):
	var image_size = biome_image.get_size()

	for y in range(max(0, int(center.y - radius)), min(image_size.y, int(center.y + radius))):
		for x in range(max(0, int(center.x - radius)), min(image_size.x, int(center.x + radius))):
			var distance = Vector2(x, y).distance_to(center)
			if distance <= radius:
				var alpha = color.a * (1.0 - distance / radius) * 0.5
				var final_color = Color(color.r, color.g, color.b, alpha)
				biome_image.set_pixel(x, y, final_color)

func toggle_biome_visibility():
	biomes_visible = !biomes_visible
	visible = biomes_visible
	biome_layer_toggled.emit(biomes_visible)
	print("Biome layer visibility: ", biomes_visible)

func set_biome_visibility(is_visible: bool):
	if biomes_visible != is_visible:
		biomes_visible = is_visible
		visible = biomes_visible
		biome_layer_toggled.emit(biomes_visible)
		print("Biome layer visibility set to: ", biomes_visible)

func set_biome_opacity(new_opacity: float):
	biome_opacity = clamp(new_opacity, 0.0, 1.0)
	_update_biome_opacity()
	print("Biome opacity set to: ", biome_opacity)

func _update_biome_opacity():
	if not biome_image:
		return

	var image_size = biome_image.get_size()

	for y in range(image_size.y):
		for x in range(image_size.x):
			var pixel = biome_image.get_pixel(x, y)
			if pixel.a > 0:
				pixel.a = biome_opacity * 0.5
				biome_image.set_pixel(x, y, pixel)

	biome_texture.set_image(biome_image)

func get_biome_at_position(world_pos: Vector2) -> String:
	if not biome_image:
		return ""

	var image_size = biome_image.get_size()
	var pixel_pos = Vector2(
		int(world_pos.x * image_size.x / 4096.0),
		int(world_pos.y * image_size.y / 2048.0)
	)

	if pixel_pos.x < 0 or pixel_pos.x >= image_size.x or pixel_pos.y < 0 or pixel_pos.y >= image_size.y:
		return ""

	var pixel_color = biome_image.get_pixel(int(pixel_pos.x), int(pixel_pos.y))

	# Find closest matching biome color
	var closest_biome = ""
	var closest_distance = 999.0

	for biome_key in biome_colors.keys():
		var biome_color = biome_colors[biome_key].color
		var distance = _color_distance(pixel_color, biome_color)
		if distance < closest_distance:
			closest_distance = distance
			closest_biome = biome_key

	return closest_biome if closest_distance < 0.5 else ""

func _color_distance(color1: Color, color2: Color) -> float:
	var dr = color1.r - color2.r
	var dg = color1.g - color2.g
	var db = color1.b - color2.b
	return sqrt(dr * dr + dg * dg + db * db)

func get_biome_info(biome_key: String) -> Dictionary:
	return biome_colors.get(biome_key, {})

func get_all_biomes() -> Dictionary:
	return biome_colors.duplicate()

func add_custom_biome(key: String, name: String, color: Color):
	biome_colors[key] = {"color": color, "name": name}
	print("Custom biome added: ", name, " (", key, ")")

func remove_biome(key: String):
	if key in biome_colors:
		biome_colors.erase(key)
		print("Biome removed: ", key)

func get_biome_texture() -> ImageTexture:
	return biome_texture

func load_biome_map_from_file(file_path: String) -> bool:
	# TODO: Load biome map from file provided by project owner
	print("Loading biome map from: ", file_path)
	return false

func save_biome_configuration(file_path: String) -> bool:
	# TODO: Save current biome configuration
	print("Saving biome configuration to: ", file_path)
	return false
