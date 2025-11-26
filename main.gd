extends Node2D

@export var player_count: int = 2
@export var base_scene: PackedScene = preload("res://scenes/buildings/base/Base.tscn")
@export var map_edge_buffer_tiles: int = 2

@onready var camera: Camera2D = $RtsCamera
@onready var terrain_map: TerrainMap = $TerrainMap
@onready var game: Node = get_node_or_null("/root/Game")

var _bases: Array[BaseBuilding] = []

func _ready() -> void:
	set_process_input(true)
	set_process(true)
	call_deferred("_initialize_world")

func _initialize_world() -> void:
	if terrain_map:
		_update_camera_bounds()
		_spawn_bases()
		
func _spawn_bases() -> void:
	if base_scene == null or terrain_map == null:
		return
	if not get_tree():
		return
	var existing: Array = get_tree().get_nodes_in_group("bases")
	if existing.size() > 0:
		print("[World] Bases already present, skipping auto placement")
		_bases.clear()
		for n in existing:
			var existing_base: BaseBuilding = n as BaseBuilding
			if existing_base:
				_bases.append(existing_base)
				_register_building_in_terrain(existing_base)
		return
	if not terrain_map.enable_random_generation:
		#if _spawn_bases_from_layout():
		print("[World] No layout bases found; using procedural placement fallback")
		return
	_bases.clear()
	var grid_size: Vector2i = terrain_map.get_grid_size()
	if grid_size.x <= 0 or grid_size.y <= 0:
		return
	var spawn_count: int = max(player_count, 1)
	var placed: Array[Rect2i] = []
	for index in range(spawn_count):
		var base_node: BaseBuilding = base_scene.instantiate() as BaseBuilding
		if base_node == null:
			continue
		base_node.is_player = index == 0
		base_node.team_id = "player" if index == 0 else "enemy_%d" % index
		base_node.team_color = game.get_team_color(base_node.team_id)
		var footprint: Vector2i = Vector2i(max(base_node.width_in_tiles, 1), max(base_node.height_in_tiles, 1))
		var origin: Vector2i = _base_origin_for_index(index, spawn_count, footprint, grid_size, placed)
		if origin.x < 0:
			print("[World] Failed to find placement for base %d" % index)
			base_node.queue_free()
			continue
		var buffer: int = 1
		var buffered_origin: Vector2i = Vector2i(origin.x - buffer, origin.y - buffer)
		var buffered_size: Vector2i = Vector2i(footprint.x + buffer * 2, footprint.y + buffer * 2)
		terrain_map.clear_impassable_in_rect(buffered_origin, buffered_size)
		var area: Rect2 = terrain_map.tiles_to_world_rect(origin, footprint)
		base_node.global_position = area.get_center()
		add_child(base_node)
		_register_building_in_terrain(base_node, origin, footprint)
		placed.append(Rect2i(origin, footprint))
		_bases.append(base_node)
		var owner_label: String = "player" if base_node.is_player else "enemy"
		print("[World] Placed %s base at tiles %s size %s" % [owner_label, str(origin), str(footprint)])
		
func _update_camera_bounds() -> void:
	if not camera or not terrain_map:
		return
	camera.map_world_rect = terrain_map.get_world_rect()
	
func _register_building_in_terrain(node: Node, origin: Vector2i = Vector2i(-1, -1), footprint: Vector2i = Vector2i.ZERO) -> void:
	if terrain_map == null or node == null:
		return
	var fp: Vector2i = footprint
	if fp == Vector2i.ZERO:
		var width_val: Variant = node.get("width_in_tiles") if node.has_method("get") else null
		var height_val: Variant = node.get("height_in_tiles") if node.has_method("get") else null
		if width_val != null and height_val != null:
			fp = Vector2i(max(int(width_val), 1), max(int(height_val), 1))
	if fp == Vector2i.ZERO:
		fp = Vector2i.ONE
	var origin_tile: Vector2i = origin
	if origin_tile.x < 0 or origin_tile.y < 0:
		var half_size: Vector2 = Vector2(fp.x, fp.y) * float(terrain_map.tile_size) * 0.5
		var top_left: Vector2 = node.global_position - half_size
		origin_tile = terrain_map.get_tile_coords(top_left)
	terrain_map.register_building(node, origin_tile, fp)
	
func _base_origin_for_index(index: int, total: int, footprint: Vector2i, grid_size: Vector2i, placed: Array[Rect2i]) -> Vector2i:
	var buffer: int = max(map_edge_buffer_tiles, 0)
	var min_x: int = buffer
	var min_y: int = buffer
	var max_x: int = grid_size.x - footprint.x - buffer
	var max_y: int = grid_size.y - footprint.y - buffer
	if max_x < min_x or max_y < min_y:
		return Vector2i(-1, -1)
	var anchor: Vector2 = _base_anchor_ratio(index, total)
	var origin: Vector2i = Vector2i(
		int(round(lerp(float(min_x), float(max_x), clamp(anchor.x, 0.0, 1.0)))),
		int(round(lerp(float(min_y), float(max_y), clamp(anchor.y, 0.0, 1.0))))
	)
	origin = Vector2i(
		clamp(origin.x, min_x, max_x),
		clamp(origin.y, min_y, max_y)
	)
	if _is_far_from_existing(origin, footprint, placed):
		return origin
	var mirrored: Vector2i = _mirror_origin(origin, footprint, grid_size, buffer)
	if _is_far_from_existing(mirrored, footprint, placed):
		return mirrored
	return origin


func _mirror_origin(origin: Vector2i, footprint: Vector2i, grid_size: Vector2i, buffer: int) -> Vector2i:
	var max_x: int = grid_size.x - footprint.x - buffer
	var max_y: int = grid_size.y - footprint.y - buffer
	var mirrored: Vector2i = Vector2i(
		max_x - (origin.x - buffer),
		max_y - (origin.y - buffer)
	)
	return Vector2i(
		clamp(mirrored.x, buffer, max_x),
		clamp(mirrored.y, buffer, max_y)
	)


func _is_far_from_existing(origin: Vector2i, footprint: Vector2i, placed: Array[Rect2i]) -> bool:
	if placed.is_empty():
		return true
	var center: Vector2 = Vector2(origin) + Vector2(footprint) * 0.5
	for rect in placed:
		var other_center: Vector2 = Vector2(rect.position) + Vector2(rect.size) * 0.5
		var min_distance: float = (float(max(rect.size.x, rect.size.y) + max(footprint.x, footprint.y)) * 0.5) + 4.0
		if center.distance_to(other_center) < min_distance:
			return false
	return true


func _base_anchor_ratio(index: int, total: int) -> Vector2:
	if total <= 1:
		return Vector2(0.1, 0.5)
	var angle: float = TAU * float(index) / float(total)
	var radius: float = 0.4
	return Vector2(0.5, 0.5) + Vector2(cos(angle), sin(angle)) * radius
