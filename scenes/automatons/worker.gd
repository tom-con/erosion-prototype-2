extends CharacterBody2D
class_name Worker

@export var move_speed: float = 70.0
@export var resource_arrive_distance: float = 28.0
@export var deposit_distance: float = 32.0
@export var gather_duration: float = 2.25
@export var search_radius_tiles: int = 100
@export var harvest_resources: PackedStringArray = PackedStringArray(["wood", "stone", "food", "iron"])
@export var backpack_capacity: int = 100

var home_base: BaseBuilding = null
var team_id: String = ""
var is_player: bool = true
var team_color: Color = Color.WHITE

const STATE_IDLE := 0
const STATE_MOVING_TO_RESOURCE := 1
const STATE_HARVESTING := 2
const STATE_RETURNING := 3

var _backpack: Dictionary = {
	"wood": 0,
	"stone": 0,
	"food": 0,
	"iron": 0
}

@onready var shader: Shader = load("res://scenes/vfx/shaders/team_color.gdshader")
@onready var _game: Game = get_node_or_null("/root/Game")
@onready var _terrain_map: TerrainMap = _find_terrain_map()

var _state: int = STATE_IDLE
var _target_tile: Vector2i = Vector2i(-1, -1)
var _gather_timer: float = 0.0
var _exception_refresh_timer: float = 0.0

func _ready() -> void:
	add_to_group("workers")
	z_index = 5
	if _terrain_map:
		_terrain_map.harvest_tags_changed.connect(_on_harvest_tags_changed)

func configure_worker(base: BaseBuilding, new_team_id: String, color: Color, player_owned: bool) -> void:
	home_base = base
	team_id = new_team_id
	is_player = player_owned
	team_color = color
	_apply_team_color()
	
func _physics_process(delta: float) -> void:
	_exception_refresh_timer -= delta
	if _exception_refresh_timer <= 0.0:
		_exception_refresh_timer = 0.75
		_refresh_friendly_unit_exceptions()
	if _state != STATE_RETURNING and _should_return_to_deposit():
		_state = STATE_RETURNING
	match _state:
		STATE_IDLE:
			velocity = Vector2.ZERO
			$AnimatedSprite2D.play("idle")
			if _should_return_to_deposit():
				_state = STATE_RETURNING
				return
			if not _try_acquire_resource():
				return
		STATE_MOVING_TO_RESOURCE:
			if _should_return_to_deposit():
				_state = STATE_RETURNING
				return
			if _move_toward_position(_resource_world_position(), delta, resource_arrive_distance):
				_state = STATE_HARVESTING
				_gather_timer = 0.0
		STATE_HARVESTING:
			$AnimatedSprite2D.play("harvest")
			if _should_return_to_deposit():
				_state = STATE_RETURNING
				return
			velocity = Vector2.ZERO
			_gather_timer += delta
			if _gather_timer >= gather_duration:
				_gather_timer = 0.0
				_collect_resource()
		STATE_RETURNING:
			if _move_toward_position(_deposit_target_position(), delta, _deposit_arrive_threshold()):
				_deposit_resource()

func _move_toward_position(goal: Vector2, delta: float, arrive_distance: float) -> bool:
	if goal == Vector2.INF:
		return true
	var to_goal: Vector2 = goal - global_position
	var dist: float = to_goal.length()
	if dist <= arrive_distance:
		velocity = Vector2.ZERO
		return true
	$AnimatedSprite2D.play("walk")
	var direction: Vector2 = to_goal.normalized()
	velocity = direction * move_speed
	move_and_slide()
	return false

#TODO: WHAT THIS
func _resource_world_position() -> Vector2:
	if _terrain_map and _target_tile.x >= 0:
		var tile: Vector2i = _target_tile
		var neighbor: Vector2i = _find_passable_neighbor(tile)
		if neighbor.x >= 0:
			return _terrain_map.get_tile_center(neighbor)
		return _terrain_map.get_tile_center(tile)
	return global_position
	
func _deposit_target_position() -> Vector2:
	var dropoff: Node = _nearest_dropoff()
	if dropoff:
		return dropoff.get_collision_center()
	return global_position
	
func _deposit_arrive_threshold() -> float:
	var dropoff: Node = _nearest_dropoff()
	if dropoff and dropoff.has_method("get_collision_radius"):
		return deposit_distance + float(dropoff.get_collision_radius())
	return deposit_distance
	
func _nearest_dropoff() -> Node:
	var best: Node = null
	var best_dist: float = INF
	for node in get_tree().get_nodes_in_group("dropoffs"):
		if node == null or not is_instance_valid(node):
			continue
		var node_team: String = team_id
		if node.has_method("get"):
			var val: Variant = node.get("team_id")
			if val != null:
				node_team = str(val)
		if node_team != team_id:
			continue
		if not node.has_method("get_collision_center"):
			continue
		var dist: float = global_position.distance_to(node.get_collision_center())
		if dist < best_dist:
			best_dist = dist
			best = node
	return best
	
func _try_acquire_resource(force: bool = false) -> bool:
	if not _terrain_map:
		return false
	var allowed: Array = harvest_resources
	var target: Variant = null
	var tile: Vector2i = _terrain_map.get_tile_coords(global_position)
	if is_player:
		target = _terrain_map.find_nearest_marked_tile(tile, allowed, search_radius_tiles)
	if not (target is Vector2i):
		target = _terrain_map.find_nearest_harvestable_tile(tile, allowed, search_radius_tiles)
	if target is Vector2i:
		if not force and _target_tile == target and _state == STATE_MOVING_TO_RESOURCE:
			return true
		_target_tile = target
		_state = STATE_MOVING_TO_RESOURCE
		return true
	if _get_carried_amount() > 0:
		print("IN HERE FOR SOME REASON")
		_state = STATE_RETURNING
	return false

func _collect_resource() -> void:
	if not _terrain_map or _target_tile.x < 0:
		if _should_return_to_deposit():
			_state = STATE_RETURNING
		else:
			_state = STATE_IDLE
	var capacity_left: int = _remaining_capacity()
	var harvest: Dictionary = _terrain_map.harvest_tile(_target_tile, capacity_left)
	var depleted: bool = bool(harvest.get("depleted", false))
	if harvest.is_empty():
		if depleted:
			_target_tile = Vector2i(-1, -1)
		_state = STATE_IDLE
		return
	var res_type: String = harvest.get("resource_type", "")
	var gained: int = int(harvest.get("amount", 0))
	if res_type == "" or gained <= 0:
		if depleted:
			_target_tile = Vector2i(-1, -1)
		_state = STATE_IDLE
		return
	_add_to_backpack(res_type, gained)
	if _should_return_to_deposit():
		_state = STATE_RETURNING
		return
	if depleted:
		_target_tile = Vector2i(-1, -1)
		_state = STATE_IDLE
		_try_acquire_resource()
	else:
		_state = STATE_HARVESTING

func _deposit_resource() -> void:
	if _game and _game.has_method("add_resource"):
		for r in _backpack.keys():
			if _backpack[r] > 0:
				_game.add_resource(team_id, r, _backpack[r])
				_backpack[r] = 0

func _get_carried_amount() -> int:
	var total: int = 0
	for r in _backpack.keys():
		total += _backpack[r]
	return total

func _add_to_backpack(res_type: String, amt: int) -> void:
	if not _backpack.has(res_type):
		print("Invalid _add_to_backpack resource")
	_backpack[res_type] = _backpack[res_type] + amt

func _remaining_capacity() -> int:
	return backpack_capacity - _get_carried_amount()

func _should_return_to_deposit() -> bool:
	return _get_carried_amount() >= backpack_capacity
	
func _find_terrain_map() -> TerrainMap:
	for node in get_tree().get_nodes_in_group("terrain_map"):
		if node is TerrainMap:
			return node
	return null
	
func _apply_team_color() -> void:
	if not team_color:
		print("Worker invalid team color")
		return
	$AnimatedSprite2D.material = ShaderMaterial.new()
	$AnimatedSprite2D.material.shader = shader
	$AnimatedSprite2D.material.set_shader_parameter("team_color", team_color)
	
func _find_passable_neighbor(tile: Vector2i) -> Vector2i:
	if not _terrain_map:
		return Vector2i(-1, -1)
	var offsets: Array = [
		Vector2i(1, 0),
		Vector2i(-1, 0),
		Vector2i(0, 1),
		Vector2i(0, -1),
		Vector2i(1, 1),
		Vector2i(-1, -1),
		Vector2i(1, -1),
		Vector2i(-1, 1)
	]
	for offset in offsets:
		var candidate: Vector2i = tile + offset
		if _terrain_map.is_tile_passable(candidate):
			return candidate
	return Vector2i(-1, -1)
	
func _refresh_friendly_unit_exceptions() -> void:
	if not is_inside_tree():
		return
	for node in get_tree().get_nodes_in_group("units"):
		if node and node.is_inside_tree():
			add_collision_exception_with(node)
			node.add_collision_exception_with(self)
	for node in get_tree().get_nodes_in_group("workers"):
		var worker: Worker = node as Worker
		if worker and worker != self and worker.is_inside_tree():
			add_collision_exception_with(worker)
			worker.add_collision_exception_with(self)
			
func _on_harvest_tags_changed(_tile: Vector2i, _is_marked: bool) -> void:
	if not is_player:
		return
	if _state == STATE_RETURNING:
		return
	if _is_marked:
		_try_acquire_resource(true)
		return
	if _target_tile == _tile:
		_target_tile = Vector2i(-1, -1)
		if _should_return_to_deposit():
			_state = STATE_RETURNING
		else:
			_state = STATE_IDLE
			_try_acquire_resource(true)
