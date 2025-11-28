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
	
func show_tile_info(type_name: String, passable: bool, speed: float, tile_coords: Vector2i, can_harvest: bool, is_marked: bool, health: int, max_health: int) -> void:
	var pretty: String = _format_tile_name(type_name)
	_title_label.text = pretty
	var passable_text = "Pathing: %s" % "Passable" if passable else "Impassable"
	var speed_text = "Speed: %.2fx %s" % speed
	var health_text = "Health: %d/%d" % [health, max_health]
	_description_label.text = "%s\n%s\n%s" % [passable_text, speed_text, health_text]
	_selected_tile = tile_coords
	_selected_tile_count = 1
	selection_can_harvest = can_harvest and not is_marked
	selection_marked = is_marked
		
func _format_tile_name(type_name: String) -> String:
	var formatted: String = type_name.replace("_", " ")
	return formatted.capitalize()
