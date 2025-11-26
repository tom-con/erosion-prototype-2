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
@onready var _sprite: Sprite2D = $Sprite2D
@onready var _terrain_map: TerrainMap = _find_terrain_map()
@onready var _collider_shape: CollisionShape2D = get_node("StaticBody2D/CollisionShape2D")

# --- Internal State ---

var _timer: float = 0.0
var _base_max_health: int = 0
var _base_spawn_interval: float = 0.0
@export var team_color: Color = Color.WHITE

func _ready() -> void:
	add_to_group("bases")
	add_to_group("buildings")
	add_to_group("dropoffs")
	health = max_health
	
	if team_id.strip_edges() == "":
		team_id = _default_team_key()
	team_color = _resolve_team_color()
	print(team_id)
	print(team_color)
	_apply_team_color()
	_apply_tile_scaling()
	

func _find_terrain_map() -> TerrainMap:
	for node in get_tree().get_nodes_in_group("terrain_map"):
		if node is TerrainMap:
			return node
	return null
	
func _default_team_key() -> String:
	return "player" if is_player else "enemy"
	
func _resolve_team_color() -> Color:
	var key: String = team_id.strip_edges() if team_id != "" else _default_team_key()
	var game: Node = get_node_or_null("/root/Game")
	if game and game.has_method("get_team_color"):
		return game.get_team_color(key)
	return Color.WHITE


func _apply_team_color() -> void:
	if _sprite and _sprite.material:
		_sprite.material = _sprite.material.duplicate()
		_sprite.material.set_shader_parameter("team_color", team_color)

func _apply_tile_scaling() -> void:
	if _terrain_map == null:
		return
	var footprint: Vector2 = Vector2(max(width_in_tiles, 1), max(height_in_tiles, 1))
	var desired_size: Vector2 = footprint * float(_terrain_map.tile_size)
	if _sprite and _sprite.texture:
		var tex_size: Vector2 = _sprite.texture.get_size()
		if tex_size.x > 0.0 and tex_size.y > 0.0:
			_sprite.scale = Vector2(desired_size.x / tex_size.x, desired_size.y / tex_size.y)
		if _collider_shape and _collider_shape.shape:
			var rect_shape: RectangleShape2D = _collider_shape.shape as RectangleShape2D
			if rect_shape:
				rect_shape.size = desired_size
	
