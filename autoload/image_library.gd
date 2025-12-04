extends Node

var buildings: Dictionary = {}
var icons: Dictionary = {}
var nodes: Dictionary = {}
var tiles: Dictionary = {}

# Set this to the folder where your icons live
const BUILDINGS_DIR := "res://assets/buildings"
const ICONS_DIR := "res://assets/icons"
const NODES_DIR := "res://assets/nodes"
const TILES_DIR := "res://assets/tiles"

func _ready() -> void:
	_load_buildings()
	_load_icons()
	_load_nodes()
	_load_tiles()

func _load_buildings() -> void:
	buildings.clear()

	var dir := DirAccess.open(BUILDINGS_DIR)
	if dir == null:
		push_error("IconLibrary: Cannot open directory: %s" % BUILDINGS_DIR)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			if file_name.ends_with(".png") or file_name.ends_with(".webp"): # adjust as needed
				var full_path := "%s/%s" % [BUILDINGS_DIR, file_name]
				# `load()` here; "preload()" can't take runtime strings
				var tex := load(full_path)
				if tex:
					# Strip extension for key, e.g. "sword.png" → "sword"
					var key := file_name.get_basename()
					buildings[key] = tex
				else:
					push_warning("IconLibrary: Failed to load %s" % full_path)
		file_name = dir.get_next()

	dir.list_dir_end()

func _load_icons() -> void:
	icons.clear()

	var dir := DirAccess.open(ICONS_DIR)
	if dir == null:
		push_error("IconLibrary: Cannot open directory: %s" % ICONS_DIR)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			if file_name.ends_with(".png") or file_name.ends_with(".webp"): # adjust as needed
				var full_path := "%s/%s" % [ICONS_DIR, file_name]
				# `load()` here; "preload()" can't take runtime strings
				var tex := load(full_path)
				if tex:
					# Strip extension for key, e.g. "sword.png" → "sword"
					var key := file_name.get_basename()
					icons[key] = tex
				else:
					push_warning("IconLibrary: Failed to load %s" % full_path)
		file_name = dir.get_next()

	dir.list_dir_end()

func _load_nodes() -> void:
	nodes.clear()

	var dir := DirAccess.open(NODES_DIR)
	if dir == null:
		push_error("IconLibrary: Cannot open directory: %s" % NODES_DIR)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			if file_name.ends_with(".png") or file_name.ends_with(".webp"): # adjust as needed
				var full_path := "%s/%s" % [NODES_DIR, file_name]
				# `load()` here; "preload()" can't take runtime strings
				var tex := load(full_path)
				if tex:
					# Strip extension for key, e.g. "sword.png" → "sword"
					var key := file_name.get_basename()
					nodes[key] = tex
				else:
					push_warning("IconLibrary: Failed to load %s" % full_path)
		file_name = dir.get_next()

	dir.list_dir_end()
	

func _load_tiles() -> void:
	tiles.clear()

	var dir := DirAccess.open(TILES_DIR)
	if dir == null:
		push_error("IconLibrary: Cannot open directory: %s" % TILES_DIR)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			if file_name.ends_with(".png") or file_name.ends_with(".webp"): # adjust as needed
				var full_path := "%s/%s" % [TILES_DIR, file_name]
				# `load()` here; "preload()" can't take runtime strings
				var tex := load(full_path)
				if tex:
					# Strip extension for key, e.g. "sword.png" → "sword"
					var key := file_name.get_basename()
					tiles[key] = tex
				else:
					push_warning("IconLibrary: Failed to load %s" % full_path)
		file_name = dir.get_next()

	dir.list_dir_end()
	

func get_building(building_name: String) -> Texture2D:
	return buildings.get(building_name, null)

func has_building(building_name: String) -> bool:
	return buildings.has(building_name)

func get_icon(icon_name: String) -> Texture2D:
	return icons.get(icon_name, null)

func has_icon(icon_name: String) -> bool:
	return icons.has(icon_name)

func get_a_node(node_name: String) -> Texture2D:
	return nodes.get(node_name, null)

func has_a_node(node_name: String) -> bool:
	return nodes.has(node_name)

func get_tile(tile_name: String) -> Texture2D:
	return tiles.get(tile_name, null)

func has_tile(tile_name: String) -> bool:
	return tiles.has(tile_name)
