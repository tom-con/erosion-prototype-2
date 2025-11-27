extends PanelContainer
class_name ContextPanel

@onready var _grid: GridContainer = get_node("MarginContainer/GridContainer")
@onready var _cost_label_scene: PackedScene = load("res://scenes/ui/elements/cost_label.tscn")

var last_action: String = ""

var _entries_cache: Dictionary = {}
var _current_entries: Dictionary = {}

func _ready() -> void:
	_clear_entries()

func set_context(entries: Array) -> void:
	_clear_entries()
	_grid.columns = entries.size()
	for e in entries:
		var id: String = e.get("id")
		if _entries_cache.has(id):
			var cached: Dictionary = _entries_cache.get(id)
			cached.get("button").show()
			_current_entries[id] = cached
		else:
			var created: Dictionary = _add_entry(e)
			_grid.add_child(created.get("button"))
			_current_entries[id] = created
			
func _clear_entries() -> void:
	_grid.columns = 1
	_current_entries.clear()
	for child in _grid.get_children():
		child.hide()
	#
func _add_entry(definition: Dictionary) -> Dictionary:
	var container: VBoxContainer = VBoxContainer.new()
	container.custom_minimum_size = Vector2(120, 120)
	container.alignment = BoxContainer.ALIGNMENT_CENTER
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var tex_butt: TextureButton = TextureButton.new()
	tex_butt.custom_minimum_size = Vector2(96, 96)
	tex_butt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tex_butt.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tex_butt.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	tex_butt.focus_mode = Control.FOCUS_NONE
	tex_butt.tooltip_text = definition.get("description", "")
	
	var icon_base: Texture2D = ImageLibrary.get_icon(definition.get("icon").get("base"))
	var icon_hover: Texture2D = ImageLibrary.get_icon(definition.get("icon").get("hover"))
	
	tex_butt.texture_normal = icon_base
	tex_butt.texture_hover = icon_hover	
	
	tex_butt.pressed.connect(func() -> void:
		print("Button Pressed: %s" % definition.get("id"))	
	)

	var label: Label = Label.new()
	label.text = definition.get("label", "unknown")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(96, 20)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.set_anchor(SIDE_TOP, 1.0)
	container.add_child(label)
	container.add_child(tex_butt)
	
	if definition.has("cost"):
		var cost_info: Dictionary = definition.get("cost")
		for ci in cost_info.keys():
			var amount = cost_info.get(ci)
			var cost_label: CostLabel = _cost_label_scene.instantiate()
			cost_label.set_cost(ci, amount)
			container.add_child(cost_label)
	
	_entries_cache[definition.get("id")] = {
		"button": container,
		"definition": definition
	}
	
	return {
		"button": container,
		"definition": definition
	}
		
