extends Control
class_name InfoPanel

@onready var _title_label: Label = %TitleLabel
@onready var _description_label: Label = %DescriptionLabel

const DEFAULT_TITLE: String = 'Selection'
const DEFAULT_LINE: String = 'Select a building or tile for more information'

var selection_can_harvest: bool = false
var selection_marked: bool = false

var _selected_tile: Vector2i = Vector2i(-1, -1)
var _selected_tile_count: int = 0

func _ready() -> void:
	show_prompt()

func show_prompt() -> void:
	_title_label.text = DEFAULT_TITLE
	_description_label.text = DEFAULT_LINE
	_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_clear_tile_selection()
	
func _clear_tile_selection() -> void:
	_selected_tile = Vector2i(-1, -1)
	_selected_tile_count = 0

func show_tile_info(type_name: String, passable: bool, speed: float, tile_coords: Vector2i, can_harvest: bool, is_marked: bool, health: int, max_health: int, node_info: Dictionary = {}) -> void:
	var pretty: String = _format_tile_name(type_name)
	_title_label.text = pretty
	var passable_text = "Pathing: %s" % "Passable" if passable else "Impassable"
	var speed_text = "Speed: %.2fx" % speed
	var health_text = "Health: %d/%d" % [health, max_health]
	var desc: Array[String] = [passable_text, speed_text, health_text]
	if not node_info.is_empty():
		var node_type: String = _format_tile_name(node_info.get("node_key", ""))
		var node_res: String = node_info.get("resource_type", "")
		var node_health: int = int(node_info.get("health", 0))
		var node_amount: int = int(node_info.get("amount", 0))
		desc.append("Resource Node: %s (%s %d/%d)" % [node_type, node_res, node_health, node_amount])
	_description_label.text = "\n".join(desc)
	_selected_tile = tile_coords
	_selected_tile_count = 1
	selection_can_harvest = can_harvest and not is_marked
	selection_marked = is_marked

func show_tiles_info(tile_count: int, harvestable_count: int, marked_count: int, markable_count: int, anchor_tile: Vector2i) -> void:
	_title_label.text = "Tiles Selected"
	var number_text: String = "Tiles: %d" % tile_count
	var harvestable_text: String = "Harvestable: %d" % harvestable_count
	var marked_text: String = "Marked: %d" % marked_count
	_description_label.text = "%s\n%s\n%s" % [number_text, harvestable_text, marked_text]
	_selected_tile = anchor_tile
	_selected_tile_count = tile_count
	selection_can_harvest = markable_count > 0
	selection_marked = marked_count > 0

func show_structure_info(structure_name: String, health: int, max_health: int, structure_owner: String) -> void:
	_title_label.text = structure_name
	var health_text: String = "Health: %d / %d" % [health, max_health]
	var owner_text: String = "Owner: %s" % structure_owner
	_description_label.text = "%s\n%s" % [health_text, owner_text]
	_clear_tile_selection()
	
func _format_tile_name(type_name: String) -> String:
	var formatted: String = type_name.replace("_", " ")
	return formatted.capitalize()
