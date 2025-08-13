extends Resource
class_name GameConfig
@export var fog_radius: float = 100.0
@export var fog_trail_width: float = 20.0
@export var poi_discovery_distance: float = 50.0
@export var max_zoom: float = 5.0
@export var min_zoom: float = 0.1
@export var pan_speed: float = 500.0

func save_to_file(path: String):
	# TODO: Implement configuration saving
	pass

func load_from_file(path: String):
	# TODO: Implement configuration loading
	pass
