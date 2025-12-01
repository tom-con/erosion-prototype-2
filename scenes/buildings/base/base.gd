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

@onready var _collision_shape: CollisionShape2D = get_node("StaticBody2D/CollisionShape2D")
@onready var _sprite: Sprite2D = $Sprite2D
@onready var _terrain_map: TerrainMap = _find_terrain_map()
@onready var _collider_shape: CollisionShape2D = get_node("StaticBody2D/CollisionShape2D")
@onready var _worker_scene: PackedScene = load("res://scenes/automatons/worker.tscn")

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
	_apply_team_color()
	_apply_tile_scaling()
	_spawn_initial_workers()
	

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

func _spawn_initial_workers() -> void:
	if _worker_scene == null or initial_worker_count <= 0:
		print("[Base] %s no worker scene or zero count; skipping workers" % name)
		return
	for index in range(initial_worker_count):
		var worker: Worker = _worker_scene.instantiate()
		worker.global_position = $SpawnPoint.global_position
		worker.configure_worker(self, team_id, team_color, is_player)
		_add_to_world(worker)
		print("[Base] Spawned worker %d for %s at %s" % [index, team_id, str(worker.global_position)])

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
	
func get_collision_rect() -> Rect2:
	if _collider_shape and _collider_shape.is_inside_tree():
		var rect_shape: RectangleShape2D = _collider_shape.shape as RectangleShape2D
		if rect_shape:
			var size: Vector2 = rect_shape.size
			var origin: Vector2 = _collider_shape.global_position - size * 0.5
			return Rect2(origin, size)
	return Rect2(global_position - Vector2(128, 128), Vector2(256, 256))
	
func get_collision_radius() -> float:
	var rect_shape: RectangleShape2D = _collision_shape.shape as RectangleShape2D
	if rect_shape:
		var sz: Vector2 = rect_shape.size
		return 0.5 * Vector2(sz.x, sz.y).length()
	return 32.0
	
func get_collision_center() -> Vector2:
	if _collider_shape and _collider_shape.is_inside_tree():
		# CollisionShape2D is a Node2D; use its global_position for an accurate center
		return _collider_shape.global_position
	return global_position

func _add_to_world(node: Node) -> void:
	var world_root: Node = get_tree().current_scene
	if world_root == null:
		world_root = get_tree().root
	if world_root.is_inside_tree():
		world_root.call_deferred("add_child", node)
	else:
		world_root.add_child.call_deferred(node)
