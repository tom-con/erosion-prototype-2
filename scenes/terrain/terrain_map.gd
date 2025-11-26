extends Node2D
class_name TerrainMap

@export var tile_size: int = 32
@export var enable_random_generation: bool = true
@export var random_seed: int = 1337
@export var map_size: String = "medium"
@export var layout_rows: PackedStringArray = []
@export var draw_unit_paths: bool = false
@export var altitude_frequency: float = 0.004
@export var moisture_frequency: float = 0.007
@export var termperature_frequency: float = 0.01
@export var noise_offset: Vector2 = Vector2.ZERO

const MAP_SIZES: Dictionary = {
	"extra_small": {
		"rows": 48,
		"cols": 48
	},
	"small": {
		"rows": 96,
		"cols": 96
	},
	"medium": {
		"rows": 144,
		"cols": 144
	},
	"large": {
		"rows": 192,
		"cols": 192
	},
	"extra_large": {
		"rows": 240,
		"cols": 240
	},
	"ludicrous": {
		"rows": 480,
		"cols": 480
	},
}

const TERRAIN_TYPES: Dictionary = {
	"grassland": {
		"color": Color(0.2, 0.6, 0.25),
		"texture": "grassland.png",
		"speed": 1.0,
		"passable": true,
		"buildable": true,
		"resource_type": "",
		"harvest_amount": 0,
		"next_type": "",
		"max_health": 0
	},
	"dirt_path": {
		"color": Color(0.65, 0.52, 0.32),
		"speed": 1.25,
		"passable": true,
		"buildable": true,
		"resource_type": "",
		"harvest_amount": 0,
		"next_type": "",
		"max_health": 0
	},
	"sparse_forest": {
		"color": Color(0.1, 0.4, 0.15),
		"texture": "sparse_forest.png",
		"speed": 0.7,
		"passable": true,
		"buildable": false,
		"resource_type": "wood",
		"harvest_amount": 25,
		"next_type": "grassland",
		"max_health": 75
	},
	"dense_forest": {
		"color": Color(0.06, 0.2, 0.07),
		"texture": "dense_forest.png",
		"speed": 0.0,
		"passable": false,
		"buildable": false,
		"resource_type": "wood",
		"harvest_amount": 35,
		"next_type": "sparse_forest",
		"max_health": 150
	},
	"mountain": {
		"color": Color(0.35, 0.35, 0.35),
		"texture": "mountain.png",
		"speed": 0.0,
		"passable": false,
		"buildable": false,
		"resource_type": "stone",
		"harvest_amount": 30,
		"next_type": "dirt_path",
		"max_health": 120
	},
	"river": {
		"color": Color(0.2, 0.4, 0.85),
		"texture": "river.png",
		"speed": 0.35,
		"passable": true,
		"buildable": false,
		"resource_type": "",
		"harvest_amount": 0,
		"next_type": "",
		"max_health": 0
	},
	"sand": {
		"color": Color(0.78, 0.69, 0.5),
		"texture": "sand.png",
		"speed": 0.85,
		"passable": true,
		"buildable": true,
		"resource_type": "",
		"harvest_amount": 0,
		"next_type": "",
		"max_health": 0
	},
	"ocean": {
		"color": Color(0.05, 0.1, 0.3),
		"texture": "ocean.png",
		"speed": 0.0,
		"passable": false,
		"buildable": false,
		"resource_type": "",
		"harvest_amount": 0,
		"next_type": "",
		"max_health": 0
	}
}

const LEGEND: Dictionary = {
	"G": "grassland",
	".": "dirt_path",
	"S": "sparse_forest",
	"D": "dense_forest",
	"M": "mountain",
	"R": "river",
	"A": "sand",
	"W": "ocean"
}

var _grid: Array = []
var _cols: int = 0
var _rows: int = 0
var _world_rect: Rect2 = Rect2()
var _blockers: Array[StaticBody2D] = []
var _building_regions: Array = []
var _building_rects: Dictionary = {}
var _building_blockers: Dictionary = {}
var _terrain_textures: Dictionary = {}

func _ready() -> void:
	add_to_group("terrain_map") 
	_load_textures()
	if enable_random_generation:
		random_seed = floor(Time.get_unix_time_from_system())
	
	var selected_map_size: Dictionary = MAP_SIZES[map_size]
	if enable_random_generation:
		_build_from_noise(selected_map_size.cols, selected_map_size.rows, random_seed)
	else:
		_build_from_layout(layout_rows)
		
func _load_textures() -> void:
	# Load textures once
	var texture_keys = TERRAIN_TYPES.keys()
	
	for k in texture_keys:
		if TERRAIN_TYPES[k].has("texture"):
			var img: Image = Image.new()
			var texture: Texture2D = null
			img.load("res://scenes/terrain/%s" % TERRAIN_TYPES[k].get("texture"))
			img.resize(tile_size, tile_size)
			texture = ImageTexture.create_from_image(img)
			_terrain_textures[TERRAIN_TYPES[k].get("texture")] = texture
		
func _build_from_layout(rows: PackedStringArray) -> void:
	if rows.is_empty():
		return
	_building_rects.clear()
	_building_blockers.clear()
	_rows = rows.size()
	_cols = rows[0].length()
	_grid.resize(_rows)
	for y in range(_cols):
		var row: Array = []
		row.resize(_cols)
		var line: String = rows[y]
		for x in range(_cols):
			var key: String = line[x]
			var type_name: String = LEGEND.get(key, "grassland")
			row[x] = _make_cell(type_name)
		_grid[y] = row
	_building_regions = _scan_building_regions(rows)
	_world_rect = Rect2(Vector2.ZERO, Vector2(_cols, _rows) * float(tile_size))
	_rebuild_blockers()
	queue_redraw()
	
func _scan_building_regions(rows: PackedStringArray) -> Array:
	var regions: Array = []
	if rows.is_empty():
		return regions
	var height: int = rows.size()
	var width: int = rows[0].length()
	var visited: Array = []
	visited.resize(height)
	for y in range(height):
		var row: Array = []
		row.resize(width)
		visited[y] = row
	
	for y in range(height):
		var line: String = rows[y]
		for x in range(width):
			if visited[x][y]:
				continue
			visited[x][y] = true
			var key: String = line[x]
			if LEGEND.has(key):
				continue
			var positions: Array[Vector2i] = _flood_collect(rows, key, x, y, visited)
			if positions.is_empty():
				continue
			var region: Dictionary = _make_region_from_positions(key, positions)
			if not region.is_empty():
				regions.append(region)
	return regions
	
func clear_impassable_in_rect(origin: Vector2i, size: Vector2i, new_type: String = "grassland") -> void:
	if not TERRAIN_TYPES.has(new_type):
		return
	var x_end: int = origin.x + size.x
	var y_end: int = origin.y + size.y
	for y in range(origin.y, y_end):
		if y < 0 or y >= _rows:
			continue
		for x in range(origin.x, x_end):
			if x < 0 or x >= _cols:
				continue
			_grid[y][x] = _make_cell(new_type)
	_rebuild_blockers()
	queue_redraw()
	#_notify_tiles_changed(origin)
	
func tiles_to_world_rect(origin: Vector2i, size: Vector2i) -> Rect2:
	var top_left: Vector2 = global_position + Vector2(origin.x * tile_size, origin.y * tile_size)
	var rect_size: Vector2 = Vector2(size.x * tile_size, size.y * tile_size)
	return Rect2(top_left, rect_size)
	
func register_building(node: Node, origin_tile: Vector2i, footprint: Vector2i) -> void:
	if node == null or not is_instance_valid(node):
		return
	if footprint.x <= 0 or footprint.y <= 0:
		return
	if _building_rects.has(node.get_instance_id()):
		unregister_building(node)
	var rect: Rect2i = Rect2i(origin_tile, footprint)
	_building_rects[node.get_instance_id()] = rect
	for y in range(origin_tile.y, origin_tile.y + footprint.y):
		for x in range(origin_tile.x, origin_tile.x + footprint.x):
			var key: String = _tile_key(Vector2i(x, y))
			_building_blockers[key] = true
	#_invalidate_spawn_paths()
	#_notify_tiles_changed(origin_tile)


func unregister_building(node: Node) -> void:
	if node == null:
		return
	var key_id: int = node.get_instance_id()
	if not _building_rects.has(key_id):
		return
	var rect: Rect2i = _building_rects[key_id]
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			_building_blockers.erase(_tile_key(Vector2i(x, y)))
	_building_rects.erase(key_id)
	#_invalidate_spawn_paths()
	#_notify_tiles_changed(rect.position)
	
# This is an algorithm to return an Array of Vector2i Coords, defining a rectangular region.
# It returns all coords within the region.
# It utilizes a "visited" value to reduce inefficiency in future scans
func _flood_collect(rows: PackedStringArray, key: String, start_x: int, start_y: int, visited) -> Array[Vector2i]:
	var coords: Array[Vector2i] = []
	var h: int = rows.size()
	var w: int = rows[0].length()
	var queue: Array[Vector2i] = []
	queue.append(Vector2i(start_x, start_y))
	visited[start_y][start_x] = true
	while not queue.is_empty():
		var cur: Vector2i = queue.pop_front()
		coords.append(cur)
		for dir in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0,1), Vector2i(0, -1)]:
			var next_x: int = cur.x + dir.x
			var next_y: int = cur.y + dir.y
			# If next_x or next_y is not within bounds, skip
			if next_x < 0 or next_x >= w or next_y < 0 or next_y >= h:
				continue
			if visited[next_y][next_x]:
				continue
			# If we don't match the type we are looking for, skip
			if rows[next_y][next_x] != key:
				continue
			visited[next_y][next_x] = true
			queue.append(Vector2i(next_x, next_y))
	return coords
	
# This func calculates the 4 corner coordinates of a region
# If region is not rectangular, return nothing
func _make_region_from_positions(marker: String, coords: Array[Vector2i]) -> Dictionary:
	if coords.is_empty():
		return {}
	var min_x: int = coords[0].x
	var max_x: int = coords[0].x
	var min_y: int = coords[0].y
	var max_y: int = coords[0].y
	for c in coords:
		min_x = min(min_x, c.x)
		max_x = max(max_x, c.x)
		min_y = min(min_y, c.y)
		max_y = max(max_y, c.y)
	var width: int = max_x - min_x + 1
	var height: int = max_y - min_y + 1
	if width * height != coords.size():
		print("[Layout] Marker %s is non-rectangular at tiles [%d,%d] size %dx%d; skipping" % [marker, min_x, min_y, width, height])
		return {}
	#TODO: Make this more extendable
	if marker == "B" and width != height:
		print("[Layout] Base marker region for %s must be square; got %dx%d; skipping" % [marker, width, height])
		return {}
	return {
		"marker": marker,
		"origin": Vector2i(min_x, min_y),
		"size": Vector2i(width, height)
	}
	
func _tile_key(tile: Vector2i) -> String:
	return "%d,%d" % [tile.x, tile.y]

	
func _build_from_noise(cols: int, rows: int, rand_seed: int) -> void:
	_cols = max(cols, 1)
	_rows = max(rows, 1)
	_building_rects.clear()
	_building_blockers.clear()
	_grid.resize(_rows)
	
	var altitude_noise: FastNoiseLite = FastNoiseLite.new()
	altitude_noise.seed = rand_seed
	altitude_noise.frequency = altitude_frequency
	altitude_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	altitude_noise.fractal_type = FastNoiseLite.FRACTAL_PING_PONG
	
	var moisture_noise: FastNoiseLite = FastNoiseLite.new()
	moisture_noise.seed = rand_seed + 1337
	moisture_noise.frequency = moisture_frequency
	moisture_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	moisture_noise.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	
	var temperature_noise: FastNoiseLite = FastNoiseLite.new()
	temperature_noise.seed = rand_seed + 2673
	temperature_noise.frequency = termperature_frequency
	temperature_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	
	for y in range(_rows):
		var row: Array = []
		row.resize(_cols)
		for x in range(_cols):
			var pos: Vector2 = Vector2(x, y) + noise_offset
			var alt: float = _normalize_noise(altitude_noise.get_noise_2d(pos.x, pos.y))
			var moist: float = _normalize_noise(moisture_noise.get_noise_2d(pos.x, pos.y))
			var temp: float = _normalize_noise(temperature_noise.get_noise_2d(pos.x, pos.y))
			var type_name: String = _biome_from_layers(alt, moist, temp)
			row[x] = _make_cell(type_name)
		_grid[y] = row
	
	_building_regions = []
	_world_rect = Rect2(Vector2.ZERO, Vector2(_cols, _rows) * float(tile_size))
	_rebuild_blockers()
	queue_redraw()

func _normalize_noise(value: float) -> float:
	# FastNoiseLite returns -1..1
	return clamp((value + 1.0) * 0.5, 0.0, 1.0)

func _biome_from_layers(altitude: float, moisture: float, temperature: float) -> String:
	if altitude < 0.25:
		return "ocean"
	if altitude < 0.35:
		return "river" if moisture > 0.55 else "sand"
	if altitude > 0.75:
		return "mountain"
	if altitude > 0.68 and moisture < 0.35:
		return "mountain"
	if moisture > 0.7:
		return "dense_forest"
	if moisture > 0.6:
		return "sparse_forest"
	if temperature > 0.7 and moisture < 0.45:
		return "sand"
	if moisture < 0.25:
		return "sand"
	return "grassland"
	
func _make_cell(type_name: String) -> Dictionary:
	var fallback: Dictionary = TERRAIN_TYPES.get("grassland", {})
	var template: Dictionary = TERRAIN_TYPES.get(type_name, fallback)
	var instance: Dictionary = template.duplicate(true)
	var max_health: int = instance.get("max_health", instance.get("harvest_amount", 0))
	if not instance.has("health"):
		instance["health"] = max_health
	return {
		"type": type_name,
		"data": instance
	}
	
func _set_tile_type(tile: Vector2i, type_name: String) -> void:
	if not is_tile_within_bounds(tile):
		return
	if not TERRAIN_TYPES.has(type_name):
		return
	_grid[tile.y][tile.x] = _make_cell(type_name)
	queue_redraw()
	call_deferred("_rebuild_blockers")
	#_notify_tile_changes(tile)
	
func _rebuild_blockers() -> void:
	for blocker in _blockers:
		if is_instance_valid(blocker):
			blocker.queue_free()
	_blockers.clear()
	
	for y in range(_rows):
		for x in range(_cols):
			var cell: Dictionary = _grid[x][y]
			if not cell:
				continue
			var info: Dictionary = cell["data"]
			if not info.get("passable", true):
				var blocker: StaticBody2D = StaticBody2D.new()
				blocker.name = "Blocker_%d_%d" % [x, y]
				var shape: CollisionShape2D = CollisionShape2D.new()
				var rect: RectangleShape2D = RectangleShape2D.new()
				rect.size = Vector2(tile_size, tile_size)
				shape.shape = rect
				blocker.add_child(shape)
				blocker.position = Vector2(x * tile_size + tile_size * 0.5, y * tile_size + tile_size * 0.5)
				add_child(blocker)
				_blockers.append(blocker)
				
func get_world_rect() -> Rect2:
	return _world_rect

func get_grid_size() -> Vector2i:
	return Vector2i(_cols, _rows)
	
func is_tile_within_bounds(tile: Vector2i) -> bool:
	return tile.x >= 0 and tile.x < _cols and tile.y >= 0 and tile.y < _rows
		
func get_tile_coords(world_position: Vector2) -> Vector2i:
	var local: Vector2 = world_position - global_position
	var x: int = int(floor(local.x / tile_size))
	var y: int = int(floor(local.y / tile_size))
	return Vector2i(x, y)

func get_cell(x: int, y: int) -> Dictionary:
	if x < 0 or x >= _cols or y < 0 or y >= _rows:
		return {}
	return _grid[y][x]

func get_cell_at_world(world_position: Vector2) -> Dictionary:
	var coords: Vector2i = get_tile_coords(world_position)
	return get_cell(coords.x, coords.y)

func get_tile_type(tile: Vector2i) -> String:
	var cell: Dictionary = get_cell(tile.x, tile.y)
	return cell.get("type", "")

func get_tile_rect(tile: Vector2i) -> Rect2:
	var origin: Vector2 = global_position + Vector2(tile.x * tile_size, tile.y * tile_size)
	return Rect2(origin, Vector2(tile_size, tile_size))
	
func get_tile_center(tile: Vector2i) -> Vector2:
	var offset: Vector2 = Vector2(tile.x + 0.5, tile.y + 0.5) * float(tile_size)
	return global_position + offset
	
func _draw() -> void:
	if _grid.is_empty():
		return
	for y in range(_rows):
		for x in range(_cols):
			var cell: Dictionary = _grid[y][x]
			if not cell:
				continue
			var info: Dictionary = cell["data"]
			var color: Color = info.get("color", Color.WHITE)
			var rect: Rect2 = Rect2(Vector2(x, y) * float(tile_size), Vector2(tile_size, tile_size))
			if info.has("texture"):
				var texture: Texture2D = _terrain_textures.get(info.get("texture"))
				draw_texture_rect(texture, rect, false)
			else:
				draw_rect(rect, color, true)
			draw_rect(rect, Color(0, 0, 0, 0.1), false, 1.0)
			
			
