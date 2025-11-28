extends Control
class_name InfoPanel

@onready var _title_label: Label = %TitleLabel
@onready var _description_label: Label = %DescriptionLabel

const DEFAULT_TITLE: String = 'Selection'
const DEFAULT_LINE: String = 'Select a building or tile for more information'

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
