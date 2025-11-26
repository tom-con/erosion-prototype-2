extends Node2D
class_name BaseBuilding

# --- Team config ---
@export var is_player: bool = true
@export var team_id: String = ""

# --- Placement Config ---
@export var width_in_tiles = 8
@export var height_in_tiles = 8

# --- Combat Config
@export var max_health: int = 200
@export var base_attack_damage: int = 8
@export var base_attack_cooldown: float = 1.5
@export var base_attack_range: float = 140.0
var health: int

# --- Economy Config
@export var worker_scene: PackedScene
@export var spearman_scene: PackedScene
@export var archer_scene: PackedScene
@export var initial_worker_count: int = 2
@export var spawn_interval: float = 15.0

@onready var _spawn_point: Node2D = $SpawnPoint
@onready var _terrain_map: TerrainMap = _find_terrain_map()


func _find_terrain_map() -> TerrainMap:
	for node in get_tree().get_nodes_in_group("terrain_map"):
		if node is TerrainMap:
			return node
	return null
