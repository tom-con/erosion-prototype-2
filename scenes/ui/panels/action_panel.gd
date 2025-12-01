extends PanelContainer
class_name ActionPanel

@onready var _game: Node = get_node_or_null("/root/Game")
@onready var _context_menu: ContextPanel = get_node_or_null("/root/Main/CanvasLayer/ContextPanel")

const HARVESTING: String = "harvesting"
const BUILDING: String = "building"

func _ready() -> void:
	if _context_menu:
		_context_menu.hide()
	
func _on_harvest_action_button_pressed() -> void:
	if not _context_menu:
		return		
	_context_menu.set_context(_context_menu.HARVESTING_CONTEXT)
		
		

func _on_build_action_button_pressed() -> void:
	if not _context_menu:
		return	
	_context_menu.set_context(_context_menu.BUILDING_CONTEXT)
