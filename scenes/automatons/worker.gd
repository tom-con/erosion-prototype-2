extends CharacterBody2D
class_name Worker

@export var move_speed: float = 70.0
@export var resource_arrive_distance: float = 10.0
@export var deposit_distance: float = 10.0
@export var gather_duration: float = 2.25
@export var search_radius_tiles: int = 40
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
const SEARCH_COOLDOWN_BASE := 0.35
const SEARCH_COOLDOWN_JITTER := 0.2
const EXCEPTION_REFRESH_INTERVAL := 1.5

var _backpack: Dictionary = {
	"wood": 0,
	"stone": 0,
	"food": 0,
	"iron": 0
}

const TEAM_SHADER: Shader = preload("res://scenes/vfx/shaders/team_color.gdshader")
@onready var _game: Game = get_node_or_null("/root/Game")
@onready var _terrain_map: TerrainMap = _find_terrain_map()

var _state: int = STATE_IDLE
var _target_tile: Vector2i = Vector2i(-1, -1)
var _gather_timer: float = 0.0
var _exception_refresh_timer: float = 0.0
var _search_cooldown: float = 0.0
var _last_units_count: int = -1
var _last_workers_count: int = -1
var _path: PackedVector2Array = PackedVector2Array()
var _path_index: int = 0
var _path_goal_tile: Vector2i = Vector2i(-1, -1)
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	add_to_group("workers")
	z_index = 5
	_rng.randomize()
	_search_cooldown = _random_search_delay()
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
	_search_cooldown = max(_search_cooldown - delta, 0.0)
	_resolve_animation()
	if _exception_refresh_timer <= 0.0:
		_exception_refresh_timer = EXCEPTION_REFRESH_INTERVAL
		_refresh_friendly_unit_exceptions()
	if _state != STATE_RETURNING and _should_return_to_deposit():
		_start_returning()
	match _state:
		STATE_IDLE:
			velocity = Vector2.ZERO
			if _should_return_to_deposit():
				_start_returning()
				return
			if _search_cooldown > 0.0:
				return
			_search_cooldown = _random_search_delay()
			if not _try_acquire_resource():
				return
		STATE_MOVING_TO_RESOURCE:
			if _should_return_to_deposit():
				_start_returning()
				return
			if _move_along_path_to(_resource_path_tile(), resource_arrive_distance):
				_state = STATE_HARVESTING
				_gather_timer = 0.0
		STATE_HARVESTING:
			if _should_return_to_deposit():
				_start_returning()
				return
			velocity = Vector2.ZERO
			_gather_timer += delta
			if _gather_timer >= gather_duration:
				_gather_timer = 0.0
				_collect_resource()
		STATE_RETURNING:
			if _move_along_path_to(_deposit_target_tile(), _deposit_arrive_threshold()):
				_deposit_resource()

func _resolve_animation() -> void:
	var anim: AnimatedSprite2D = $AnimatedSprite2D
	var current_anim: String = anim.get_animation()
	var is_playing: bool = anim.is_playing()
	
	match(_state):
		STATE_IDLE:
			if current_anim != "idle":
				anim.stop()
			if not is_playing:
				anim.play("idle")
		STATE_HARVESTING:
			if current_anim != "harvest":
				anim.stop()
			if not is_playing:
				anim.play("harvest")
		STATE_MOVING_TO_RESOURCE:
			if current_anim != "walk":
				anim.stop()
			if not is_playing:
				anim.play("walk")
		STATE_RETURNING:
			if current_anim != "walk":
				anim.stop()
			if not is_playing:
				anim.play("walk")

func _move_along_path_to(goal_tile: Vector2i, arrive_distance: float) -> bool:
	if goal_tile.x < 0 or goal_tile.y < 0:
		velocity = Vector2.ZERO
		return true
	if goal_tile != _path_goal_tile or _path.is_empty():
		_build_path_to_tile(goal_tile)
	return _follow_path(arrive_distance)

func _safe_origin_tile() -> Vector2i:
	if not _terrain_map:
		return Vector2i(-1, -1)
	var start: Vector2i = _terrain_map.get_tile_coords(global_position)
	if _terrain_map.is_tile_within_bounds(start) and _terrain_map.is_tile_passable(start):
		return start
	var max_radius: int = 4
	for radius in range(1, max_radius + 1):
		for dx in range(-radius, radius + 1):
			for dy in range(-radius, radius + 1):
				if abs(dx) != radius and abs(dy) != radius:
					continue
				var candidate: Vector2i = start + Vector2i(dx, dy)
				if not _terrain_map.is_tile_within_bounds(candidate):
					continue
				if _terrain_map.is_tile_passable(candidate):
					return candidate
	return start

func _build_path_to_tile(goal_tile: Vector2i) -> void:
	_path = PackedVector2Array()
	_path_index = 0
	_path_goal_tile = goal_tile
	if not _terrain_map:
		return
	var origin_tile: Vector2i = _safe_origin_tile()
	if not _terrain_map.is_tile_within_bounds(goal_tile) or not _terrain_map.is_tile_within_bounds(origin_tile):
		return
	_path = _terrain_map.get_path_to_goal(origin_tile, goal_tile)
	if _path.is_empty():
		_path.append(_terrain_map.get_tile_center(goal_tile))

func _follow_path(arrive_distance: float) -> bool:
	if _path.is_empty():
		velocity = Vector2.ZERO
		return false
	if _path_index >= _path.size():
		velocity = Vector2.ZERO
		return true
	var target: Vector2 = _path[_path_index]
	var to_target: Vector2 = target - global_position
	var dist: float = to_target.length()
	var is_last: bool = _path_index >= _path.size() - 1
	var threshold: float = arrive_distance if is_last else 4.0
	if dist <= threshold:
		_path_index += 1
		if _path_index >= _path.size():
			velocity = Vector2.ZERO
			return true
		target = _path[_path_index]
		to_target = target - global_position
	if to_target == Vector2.ZERO:
		velocity = Vector2.ZERO
		return _path_index >= _path.size()
	var direction: Vector2 = to_target.normalized()
	var speed_mult: float = _terrain_map.get_speed_multiplier(global_position) if _terrain_map else 1.0
	velocity = direction * move_speed * max(speed_mult, 0.05)
	move_and_slide()
	return false

#TODO: WHAT THIS
func _resource_path_tile() -> Vector2i:
	if _terrain_map and _target_tile.x >= 0:
		var neighbor: Vector2i = _find_passable_neighbor(_target_tile)
		if neighbor.x >= 0:
			return neighbor
		return _target_tile
	return Vector2i(-1, -1)

func _resource_world_position() -> Vector2:
	var tile: Vector2i = _resource_path_tile()
	if _terrain_map and tile.x >= 0:
		return _terrain_map.get_tile_center(tile)
	return global_position
	
func _deposit_target_tile() -> Vector2i:
	if not _terrain_map:
		return Vector2i(-1, -1)
	var dropoff: Node = _nearest_dropoff()
	if dropoff:
		var tile: Vector2i = _terrain_map.get_tile_coords(dropoff.get_collision_center())
		# If the dropoff exposes its footprint, pick the closest perimeter tile to this worker
		if dropoff.has_method("get_collision_rect"):
			var rect: Rect2 = dropoff.get_collision_rect()
			var top_left: Vector2i = _terrain_map.get_tile_coords(rect.position)
			var bottom_right: Vector2i = _terrain_map.get_tile_coords(rect.position + rect.size)
			var best: Vector2i = Vector2i(-1, -1)
			var best_dist: float = INF
			for y in range(top_left.y, bottom_right.y + 1):
				for x in range(top_left.x, bottom_right.x + 1):
					# Only consider perimeter cells around the rectangle
					var on_edge: bool = x == top_left.x or x == bottom_right.x or y == top_left.y or y == bottom_right.y
					if not on_edge:
						continue
					var candidate: Vector2i = Vector2i(x, y)
					if not _terrain_map.is_tile_within_bounds(candidate):
						continue
					if not _terrain_map.is_tile_passable(candidate):
						continue
					var dist: float = _terrain_map.get_tile_center(candidate).distance_to(global_position)
					if dist < best_dist:
						best_dist = dist
						best = candidate
			if best.x >= 0:
				return best
		var neighbor: Vector2i = _find_passable_neighbor(tile)
		if neighbor.x >= 0:
			return neighbor
		return tile
	return Vector2i(-1, -1)

func _deposit_target_position() -> Vector2:
	var tile: Vector2i = _deposit_target_tile()
	if _terrain_map and tile.x >= 0:
		return _terrain_map.get_tile_center(tile)
	return global_position
	
func _deposit_arrive_threshold() -> float:
	var dropoff: Node = _nearest_dropoff()
	if dropoff and dropoff.has_method("get_collision_radius"):
		return deposit_distance + float(dropoff.get_collision_radius())
	return deposit_distance
	
func _start_returning() -> void:
	_build_path_to_tile(_deposit_target_tile())
	_state = STATE_RETURNING
	
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
	var target: Variant = null
	var tile: Vector2i = _terrain_map.get_tile_coords(global_position)
	if is_player:
		target = _terrain_map.find_nearest_marked_tile(tile, search_radius_tiles)
	if not (target is Vector2i):
		var tile_target: Variant = _terrain_map.find_nearest_resource_tile(tile, search_radius_tiles)
		var node_target: Variant = _terrain_map.find_nearest_resource_node(tile, search_radius_tiles)
		if tile_target is Vector2i and node_target is Vector2i:
			var tile_dist: int = max(abs(tile_target.x - tile.x), abs(tile_target.y - tile.y))
			var node_dist: int = max(abs(node_target.x - tile.x), abs(node_target.y - tile.y))
			target = tile_target if tile_dist <= node_dist else node_target
		elif tile_target is Vector2i:
			target = tile_target
		elif node_target is Vector2i:
			target = node_target
	if target is Vector2i:
		if not force and _target_tile == target and _state == STATE_MOVING_TO_RESOURCE:
			return true
		_target_tile = target
		_state = STATE_MOVING_TO_RESOURCE
		_build_path_to_tile(_resource_path_tile())
		return true
	if _get_carried_amount() > 0:
		print("IN HERE FOR SOME REASON")
		_start_returning()
	return false

func _collect_resource() -> void:
	if not _terrain_map or _target_tile.x < 0:
		if _should_return_to_deposit():
			_start_returning()
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
		_start_returning()
		return
	if depleted:
		_target_tile = Vector2i(-1, -1)
		_state = STATE_IDLE
		_try_acquire_resource()
	else:
		_state = STATE_HARVESTING

func _deposit_resource() -> void:
	var has_game: bool = _game and _game.has_method("add_resources")
	if has_game:
		_game.add_resources(team_id, _backpack)
	_empty_backpack()
	# Clear target and reset state so we don't re-enter RETURNING with leftover cargo
	_target_tile = Vector2i(-1, -1)
	_path = PackedVector2Array()
	_path_index = 0
	_path_goal_tile = Vector2i(-1, -1)
	# Nudge off blocked tiles (e.g., inside the base footprint) so the next path can start from walkable ground
	if _terrain_map:
		var origin_tile: Vector2i = _terrain_map.get_tile_coords(global_position)
		if not _terrain_map.is_tile_passable(origin_tile):
			var safe_tile: Vector2i = _safe_origin_tile()
			if safe_tile.x >= 0:
				global_position = _terrain_map.get_tile_center(safe_tile)
	_state = STATE_IDLE
	_try_acquire_resource(true)
	
func _empty_backpack() -> void:
	_backpack = {
	"wood": 0,
	"stone": 0,
	"food": 0,
	"iron": 0
}
	

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
	$AnimatedSprite2D.material.shader = TEAM_SHADER
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
	var units: Array = get_tree().get_nodes_in_group("units")
	var workers: Array = get_tree().get_nodes_in_group("workers")
	var units_count: int = units.size()
	var workers_count: int = workers.size()
	if units_count == _last_units_count and workers_count == _last_workers_count:
		return
	_last_units_count = units_count
	_last_workers_count = workers_count
	for node in units:
		if node and node.is_inside_tree():
			add_collision_exception_with(node)
			node.add_collision_exception_with(self)
	for node in workers:
		var worker: Worker = node as Worker
		if worker and worker != self and worker.is_inside_tree():
			add_collision_exception_with(worker)
			worker.add_collision_exception_with(self)
			
func _random_search_delay() -> float:
	return SEARCH_COOLDOWN_BASE + _rng.randf() * SEARCH_COOLDOWN_JITTER

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
			_start_returning()
		else:
			_state = STATE_IDLE
			_try_acquire_resource(true)
