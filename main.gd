extends Node2D

@export var player_count: int = 2
@export var base_scene: PackedScene = preload("res://scenes/buildings/base/Base.tscn")
@export var map_edge_buffer_tiles: int = 2

@onready var camera: Camera2D = $RtsCamera
@onready var terrain_map: TerrainMap = $TerrainMap
@onready var info_panel: InfoPanel = get_node("CanvasLayer/InfoPanel")
@onready var resource_panel: ResourcePanel = get_node("CanvasLayer/ResourcePanel")
@onready var action_panel: ActionPanel = get_node("CanvasLayer/ActionPanel")
@onready var context_panel: ContextPanel = get_node("CanvasLayer/ContextPanel")
@onready var selection_highlight: SelectionHighlight = $SelectionHighlight
@onready var game: Node = get_node_or_null("/root/Game")

const TILE_REFRESH_INTERVAL: float = 0.25
var _selected_tile: Vector2i = Vector2i(-1, -1)
var _selected_tiles: Array[Vector2i] = []
var _tile_refresh_elapsed: float = 0.0

var _is_placing_building: bool = false

const DRAG_MIN_DISTANCE: float = 8.0
var _is_dragging: bool = false
var _drag_start_screen: Vector2 = Vector2.ZERO
var _drag_start_world: Vector2 = Vector2.ZERO
var _drag_current_world: Vector2 = Vector2.ZERO

var _bases: Array[BaseBuilding] = []

func _ready() -> void:
	set_process_input(true)
	set_process(true)
	call_deferred("_initialize_world")
	
func _process(delta: float) -> void:
	if _selected_tiles.size() != 1:
		return
	_tile_refresh_elapsed += delta
	if _tile_refresh_elapsed < TILE_REFRESH_INTERVAL:
		return
	_tile_refresh_elapsed = 0.0
	_refresh_selected_tile_info()

func _refresh_selected_tile_info() -> void:
	if not terrain_map or _selected_tiles.size() != 1:
		return
	_show_tile_details(_selected_tiles[0])

func _initialize_world() -> void:
	if terrain_map:
		_update_camera_bounds()
		_spawn_bases()
	resource_panel._render_resources_for_player()
	_focus_camera_on_player_base()
	
	
func _input(event: InputEvent) -> void:
	if _is_placing_building:
		print("PLACING BUILDING")
		#if event is InputEventMouseMotion:
			#_update_placement_preview()
		#elif event is InputEventMouseButton:
			#var mb: InputEventMouseButton = event
			#if not mb.pressed:
				#return
			#if mb.button_index == MOUSE_BUTTON_LEFT:
				#if _is_mouse_over_ui(mb.position):
					#return
				#_try_place_building()
			#if mb.button_index == MOUSE_BUTTON_RIGHT:
				#_cancel_build_mode()
		return
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed and not mb.double_click and not mb.is_echo():
				if _is_mouse_over_ui(mb.position):
					return
				_begin_drag_selection(mb.position)
			elif not mb.pressed and _is_dragging:
				_finish_drag_selection(mb.position)
	elif event is InputEventMouseMotion and _is_dragging:
		var mm: InputEventMouseMotion = event
		_update_drag_highlight(mm.position)
		
func _is_mouse_over_ui(screen_position: Vector2) -> bool:
	if info_panel and _control_has_screen_point(info_panel, screen_position):
		return true
	if resource_panel and _control_has_screen_point(resource_panel, screen_position):
		return true
	if action_panel and _control_has_screen_point(action_panel, screen_position):
		return true
	if context_panel and _control_has_screen_point(context_panel, screen_position):
		return true
	return false
	
func _control_has_screen_point(control: Control, screen_position: Vector2) -> bool:
	if not control.visible:
		return false
	var rect: Rect2 = control.get_global_rect()
	return rect.has_point(screen_position)
	
func _begin_drag_selection(screen_position: Vector2) -> void:
	_is_dragging = true
	_drag_start_screen = screen_position
	_drag_start_world = camera.get_global_mouse_position()
	_drag_current_world = _drag_start_world
	if selection_highlight:
		var rect := _make_drag_rect(_drag_start_world, _drag_current_world)
		selection_highlight.show_rect(rect)
		
func _update_drag_highlight(_screen_position: Vector2) -> void:
	_drag_current_world = camera.get_global_mouse_position()
	if selection_highlight:
		var rect := _make_drag_rect(_drag_start_world, _drag_current_world)
		selection_highlight.show_rect(rect)


func _finish_drag_selection(screen_position: Vector2) -> void:
	var end_world: Vector2 = camera.get_global_mouse_position()
	var drag_distance: float = (_drag_start_screen - screen_position).length()
	_is_dragging = false
	if selection_highlight:
		selection_highlight.hide_highlight()
	if drag_distance < DRAG_MIN_DISTANCE:
		_handle_click_at(end_world)
		return
	_select_tiles_in_rect(_drag_start_world, end_world)
	
func _make_drag_rect(a: Vector2, b: Vector2) -> Rect2:
	var origin: Vector2 = Vector2(min(a.x, b.x), min(a.y, b.y))
	var size: Vector2 = Vector2(abs(a.x - b.x), abs(a.y - b.y))
	return Rect2(origin, size)

func _handle_click_at(world_pos: Vector2) -> void:
	if _select_structure_at(world_pos):
		return
	_select_tile_at(world_pos)

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
		var team_id: String = "player" if index == 0 else "enemy_%d" % index 
		var base_node: BaseBuilding = base_scene.instantiate() as BaseBuilding
		if base_node == null:
			continue
		base_node.is_player = index == 0
		base_node.team_id = team_id
		game.initialize_resources_for_actor(team_id)
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

func _show_tile_details(tile: Vector2i) -> void:
	if not terrain_map or not info_panel:
		return
	if not terrain_map.is_tile_within_bounds(tile):
		info_panel.show_prompt()
		if selection_highlight:
			selection_highlight.hide_highlight()
		_clear_tile_selection()
		return
	var cell: Dictionary = terrain_map.get_cell(tile.x, tile.y)
	if cell.is_empty():
		info_panel.show_prompt()
		if selection_highlight:
			selection_highlight.hide_highlight()
		_clear_tile_selection()
		return
	var type_name: String = cell.get("type", "unknown")
	var data: Dictionary = cell.get("data", {})
	var passable: bool = data.get("passable", true)
	var speed: float = data.get("speed", 1.0)
	var max_health: int = int(data.get("max_health", data.get("harvest_amount", 0)))
	var health: int = int(data.get("health", max_health))
	if selection_highlight:
		selection_highlight.show_edges(_tile_edge_segments([tile]))
	var harvestable: bool = terrain_map.is_tile_harvestable(tile)
	var marked: bool = terrain_map.is_tile_marked_for_harvest(tile)
	info_panel.show_tile_info(type_name, passable, speed, tile, harvestable, marked, health, max_health)
	_selected_tile = tile
	_selected_tiles = [tile]
	_reset_tile_refresh()

func _tile_edge_segments(tiles: Array[Vector2i]) -> Array:
	var segments: Array = []
	if tiles.is_empty() or not terrain_map:
		return segments
	var tile_set: Dictionary = {}
	for tile in tiles:
		tile_set[_local_tile_key(tile)] = true
	var size: float = float(terrain_map.tile_size)
	for tile in tiles:
		var origin: Vector2 = terrain_map.global_position + Vector2(tile.x * size, tile.y * size)
		var tl: Vector2 = origin
		var tr: Vector2 = origin + Vector2(size, 0.0)
		var br: Vector2 = origin + Vector2(size, size)
		var bl: Vector2 = origin + Vector2(0.0, size)
		if not tile_set.has(_local_tile_key(tile + Vector2i(0, -1))):
			segments.append(PackedVector2Array([tl, tr]))
		if not tile_set.has(_local_tile_key(tile + Vector2i(1, 0))):
			segments.append(PackedVector2Array([tr, br]))
		if not tile_set.has(_local_tile_key(tile + Vector2i(0, 1))):
			segments.append(PackedVector2Array([br, bl]))
		if not tile_set.has(_local_tile_key(tile + Vector2i(-1, 0))):
			segments.append(PackedVector2Array([bl, tl]))
	return segments

func _select_tiles_in_rect(start_world: Vector2, end_world: Vector2) -> void:
	if not terrain_map:
		return
	var start_tile: Vector2i = terrain_map.get_tile_coords(start_world)
	var end_tile: Vector2i = terrain_map.get_tile_coords(end_world)
	var min_x: int = min(start_tile.x, end_tile.x)
	var max_x: int = max(start_tile.x, end_tile.x)
	var min_y: int = min(start_tile.y, end_tile.y)
	var max_y: int = max(start_tile.y, end_tile.y)
	var tiles: Array[Vector2i] = []
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var tile: Vector2i = Vector2i(x, y)
			if not terrain_map.is_tile_within_bounds(tile):
				continue
			if not terrain_map.is_tile_harvestable(tile):
				continue
			var cell: Dictionary = terrain_map.get_cell(tile.x, tile.y)
			if cell.is_empty():
				continue
			tiles.append(tile)
	if tiles.is_empty():
		if selection_highlight:
			selection_highlight.hide_highlight()
		if info_panel:
			info_panel.show_prompt()
		_clear_tile_selection()
		return
	if tiles.size() == 1:
		_show_tile_details(tiles[0])
		return
	_apply_multi_tile_selection(tiles)

func _apply_multi_tile_selection(tiles: Array[Vector2i]) -> void:
	_selected_tiles = tiles.duplicate()
	_selected_tile = tiles[0]
	var harvestable_count: int = _count_harvestable(tiles)
	var marked_count: int = _count_marked(tiles)
	var markable_count: int = _count_markable(tiles)
	if selection_highlight:
		selection_highlight.show_edges(_tile_edge_segments(tiles))
	if info_panel:
		info_panel.show_tiles_info(tiles.size(), harvestable_count, marked_count, markable_count, tiles[0])
	_reset_tile_refresh()

func _count_harvestable(tiles: Array[Vector2i]) -> int:
	if not terrain_map:
		return 0
	var count: int = 0
	for tile in tiles:
		if terrain_map.is_tile_harvestable(tile):
			count += 1
	return count


func _count_marked(tiles: Array[Vector2i]) -> int:
	if not terrain_map:
		return 0
	var count: int = 0
	for tile in tiles:
		if terrain_map.is_tile_marked_for_harvest(tile):
			count += 1
	return count


func _count_markable(tiles: Array[Vector2i]) -> int:
	if not terrain_map:
		return 0
	var count: int = 0
	for tile in tiles:
		if terrain_map.is_tile_harvestable(tile) and not terrain_map.is_tile_marked_for_harvest(tile):
			count += 1
	return count

func _select_structure_at(world_position: Vector2) -> bool:
	var params: PhysicsPointQueryParameters2D = PhysicsPointQueryParameters2D.new()
	params.position = world_position
	params.collide_with_areas = true
	params.collide_with_bodies = true
	params.collision_mask = 0xFFFFFFFF

	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var results: Array = space_state.intersect_point(params, 16)
	for result in results:
		var collider: Object = result.get("collider")
		if collider is Area2D:
			continue
		var building: Node = _ascend_to_building(collider)
		if building:
			print("[Select] Click hit building: %s via %s" % [building.name, collider.get_class()])
			if building is BaseBuilding:
				var hp_val: Variant = building.get("health") if building.has_method("get") else 0
				var max_hp_val: Variant = building.get("max_health") if building.has_method("get") else 0
				var hp: int = int(hp_val) if hp_val != null else 0
				var max_hp: int = int(max_hp_val) if max_hp_val != null else 0
				info_panel.show_structure_info("Base", hp, max_hp, _owner_label(building))
			#elif building is SpearmanBarracks:
				#var hp_val: Variant = building.get("health") if building.has_method("get") else 0
				#var max_hp_val: Variant = building.get("max_health") if building.has_method("get") else 0
				#var hp: int = int(hp_val) if hp_val != null else 0
				#var max_hp: int = int(max_hp_val) if max_hp_val != null else 0
				#info_panel.show_structure_info("Spearman Barracks", hp, max_hp, _owner_label(building))
			#elif building is Stockpile:
				#var hp_sp_val: Variant = building.get("health") if building.has_method("get") else 0
				#var max_hp_sp_val: Variant = building.get("max_health") if building.has_method("get") else 0
				#var hp_sp: int = int(hp_sp_val) if hp_sp_val != null else 0
				#var max_hp_sp: int = int(max_hp_sp_val) if max_hp_sp_val != null else 0
				#info_panel.show_structure_info("Stockpile", hp_sp, max_hp_sp, _owner_label(building))
			# TODO: Building upgrades logic in new context panel
			#if upgrade_panel:
				#if building is BaseBuilding or building is SpearmanBarracks:
					#upgrade_panel.show_for_target(building)
				#else:
					#upgrade_panel.hide_panel()
			#_set_selected_upgrade_target(building)
			if selection_highlight and building.has_method("get_collision_rect"):
				var rect: Rect2 = building.get_collision_rect()
				selection_highlight.show_rect(rect)
			_clear_tile_selection()
			_tile_refresh_elapsed = 0.0
			return true
	print("[Select] No structure hit")
	# TODO: Impelemnt after upgrades refactor
	#if upgrade_panel:
		#upgrade_panel.hide_panel()
	#_set_selected_upgrade_target(null)
	return false


func _select_tile_at(world_position: Vector2) -> void:
	# TODO: Upgrades logic
	#if upgrade_panel:
		#upgrade_panel.hide_panel()
	#_set_selected_upgrade_target(null)
	if not terrain_map:
		print("[Select] No terrain map available")
		info_panel.show_prompt()
		if selection_highlight:
			selection_highlight.hide_highlight()
		_clear_tile_selection()
		return
	var tile: Vector2i = terrain_map.get_tile_coords(world_position)
	if not terrain_map.is_tile_within_bounds(tile):
		print("[Select] Clicked outside map %s" % str(tile))
		info_panel.show_prompt()
		if selection_highlight:
			selection_highlight.hide_highlight()
		_clear_tile_selection()
		return
	var cell: Dictionary = terrain_map.get_cell(tile.x, tile.y)
	if cell.is_empty():
		print("[Select] Tile data missing at %s" % str(tile))
		info_panel.show_prompt()
		if selection_highlight:
			selection_highlight.hide_highlight()
		_clear_tile_selection()
		return
	_show_tile_details(tile)

func _local_tile_key(tile: Vector2i) -> String:
	return "%d,%d" % [tile.x, tile.y]

func _clear_tile_selection() -> void:
	_selected_tile = Vector2i(-1, -1)
	_selected_tiles.clear()
	_reset_tile_refresh()
	
func _reset_tile_refresh() -> void:
	_tile_refresh_elapsed = 0.0

func _ascend_to_building(node: Object) -> Node:
	if node == null:
		return null
	var current: Object = node
	while current:
		if current.is_in_group("buildings"):
			return current as Node
		if current is Node:
			current = current.get_parent()
		else:
			break
	return null

func _focus_camera_on_player_base() -> void:
	if camera == null:
		return
	var player_base: BaseBuilding = null
	for n in get_tree().get_nodes_in_group("bases"):
		var b: BaseBuilding = n as BaseBuilding
		if b and b.is_player:
			player_base = b
			break
	if player_base == null:
		return
	var desired_zoom: float = 1.0
	var desired_tiles_span: float = 24.0
	var tile_size: int = terrain_map.tile_size if terrain_map else 32
	var base_rect: Rect2 = player_base.get_collision_rect()
	var target_world_size: float = desired_tiles_span * tile_size
	if not terrain_map and player_base.tile_width > 0:
		if player_base.tile_width > 0:
			var approx_tile: float = base_rect.size.x / float(player_base.tile_width)
			if approx_tile > 0.0:
				target_world_size = desired_tiles_span * approx_tile
	var viewport_size: Vector2 = get_viewport_rect().size
	var base_axis: float = min(viewport_size.x, viewport_size.y)
	if base_axis > 0.0:
		desired_zoom = clamp(base_axis / target_world_size, camera.zoom_min, camera.zoom_max)
	var focus_position: Vector2 = player_base.get_collision_center()
	camera.global_position = focus_position
	camera._target_pos = focus_position
	camera._target_zoom = desired_zoom
	camera.zoom = Vector2(desired_zoom, desired_zoom)
	
func _owner_label(base: BaseBuilding) -> String:
	return "You" if base.is_player else "Enemy"
