extends PanelContainer
class_name ActionPanel

@onready var _game: Node = get_node_or_null("/root/Game")
@onready var _context_menu: ContextPanel = get_node_or_null("/root/Main/CanvasLayer/ContextPanel")

const HARVESTING: String = "harvesting"
const BUILDING: String = "building"

var _harvesting_context: Array[Dictionary] = [
	{
		"id": "harvest",
		"label": "Harvest",
		"icon": {
			"base": "harvest_icon",
			"hover": "harvest_highlight_icon"
		},
		"press_signal": ""
	},
	{
		"id": "unharvest",
		"label": "Clear",
		"icon": {
			"base": "unharvest_icon",
			"hover": "unharvest_highlight_icon"
		}
	}
]

var _building_context: Array[Dictionary] = [
	{
		"id": "stockpile",
		"label": "Stock",
		"description": "Another dropoff for resources",
		"cost": {
			"wood": 200	
		},
		"icon": {
			"base": "stockpile_icon",
			"hover": "stockpile_highlight_icon"
		},
		"press_signal": ""
	},
	{
		"id": "spearman_barracks",
		"label": "Spear",
		"description": "Spearman Barracks will spawn Spearman Units",
		"cost": {
			"wood": 800,
			"stone": 200
		},
		"icon": {
			"base": "spear_icon",
			"hover": "spear_highlight_icon"
		},
		"press_signal": ""
	},
		{
		"id": "archer_barracks",
		"label": "Archer",
		"description": "Archer Barracks will spawn Archer Units",
		"cost": {
			"wood": 1400,
			"stone": 400
		},
		"icon": {
			"base": "bow_icon",
			"hover": "bow_highlight_icon"
		},
		"press_signal": ""
	},
]

func _ready() -> void:
	if _context_menu:
		_context_menu.hide()
	
func _on_harvest_action_button_pressed() -> void:
	if not _context_menu:
		return
	if _context_menu.last_action == HARVESTING:
		_context_menu.hide()
		_context_menu.last_action = ""
	else:
		_context_menu.show()
		_context_menu.set_context(_harvesting_context)
		_context_menu.last_action = HARVESTING
		

func _on_build_action_button_pressed() -> void:
	if not _context_menu:
		return
	if _context_menu.last_action == BUILDING:
		_context_menu.hide()
		_context_menu.last_action = ""
	else:
		_context_menu.show()
		_context_menu.set_context(_building_context)
		_context_menu.last_action = BUILDING
