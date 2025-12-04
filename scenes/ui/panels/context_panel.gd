extends PanelContainer
class_name ContextPanel

signal mark_tiles_for_harvest()
signal unmark_tiles_for_harvest()
signal worker_purchased(team_key: String)

var _cost_label_scene: PackedScene = preload("res://scenes/ui/elements/cost_label.tscn")

@onready var _grid: GridContainer = get_node("MarginContainer/GridContainer")
@onready var _game: Game = get_node("/root/Game")

const HARVESTING_CONTEXT = "harvesting"
const BUILDING_CONTEXT = "building"
const BASE_CONTEXT = "base"
const NULL_CONTEXT = ""

var harvesting_actions: Array[Dictionary] = [
	{
		"id": "harvest",
		"label": "Harvest",
		"icon": {
			"base": "harvest_icon",
			"hover": "harvest_highlight_icon"
		},
		"press_signal": Callable(self, "_mark_selected_for_harvest")
	},
	{
		"id": "unharvest",
		"label": "Clear",
		"icon": {
			"base": "unharvest_icon",
			"hover": "unharvest_highlight_icon"
		},
		"press_signal": Callable(self, "_unmark_selected_for_harvest")
	}
]

var building_actions: Array[Dictionary] = [
	{
		"id": "stockpile",
		"label": "Stock",
		"description": "Another dropoff for resources",
		"cost_type": "core",
		"icon": {
			"base": "stockpile_icon",
			"disabled": "stockpile_disabled_icon",
			"hover": "stockpile_highlight_icon"
		},
		"press_signal": Callable(self, "_try_core_purchase").bind("stockpile")
	},
		{
		"id": "farm",
		"label": "Farm",
		"description": "A structure that generates food",
		"cost_type": "core",
		"icon": {
			"base": "farm_icon",
			"disabled": "farm_disabled_icon",
			"hover": "farm_highlight_icon"
		},
		"press_signal": Callable(self, "_try_core_purchase").bind("farm")
	},
	{
		"id": "spearman_barracks",
		"label": "Spear",
		"description": "Spearman Barracks will spawn Spearman Units",
		"cost_type": "core",
		"icon": {
			"base": "spear_icon",
			"disabled": "spear_disabled_icon",
			"hover": "spear_highlight_icon"
		},
		"press_signal": Callable(self, "_try_core_purchase").bind("spearman_barracks")
	},
		{
		"id": "archer_barracks",
		"label": "Archer",
		"description": "Archer Barracks will spawn Archer Units",
		"cost_type": "core",
		"icon": {
			"base": "bow_icon",
			"disabled": "bow_disabled_icon",
			"hover": "bow_highlight_icon"
		},
		"press_signal": Callable(self, "_try_core_purchase").bind("archer_barracks")
	},
]

var base_actions: Array[Dictionary] = [
	{
		"id": "worker",
		"label": "Worker",
		"description": "Buy a new worker to gather resources",
		"cost_type": "core",
		"icon": {
			"base": "worker_icon",
			"disabled": "worker_disabled_icon",
			"hover": "worker_highlight_icon"
		},
		"press_signal": Callable(self, "_try_core_purchase").bind("worker")
	},
	{
		"id": "spawn_rate",
		"label": "Spawn Rate",
		"description": "Increase the rate at which Spearmen spawn",
		"cost_type": "structure",
		"icon": {
			"base": "spawn_rate_icon",
			"disabled": "spawn_rate_disabled_icon",
			"hover": "spawn_rate_highlight_icon"
		}
	}
]

var spear_actions: Array[Dictionary] = [
		{
		"id": "spawn_rate",
		"label": "Spawn Rate",
		"description": "Increase the rate at which Spearmen spawn",
		"cost_type": "structure",
		"icon": {
			"base": "spawn_rate_icon",
			"hover": "spawn_rate_highlight_icon"
		}
	}
]

var last_action: String = NULL_CONTEXT

var _entries_cache: Dictionary = {}
var _current_entries: Dictionary = {}
var _current_structure_id: String = ""

func _ready() -> void:
	_clear_entries()
	_game.player_costs_changed.connect(_refresh_entries_cost)
	_game.player_resources_changed.connect(_refresh_entries_cost)
	
func _mark_selected_for_harvest() -> void:
	emit_signal("mark_tiles_for_harvest")
	
func _unmark_selected_for_harvest() -> void:
	emit_signal("unmark_tiles_for_harvest")
	
func _try_core_purchase(id: String) -> void:
	var purchased: bool = _game.purchase_core_for_team("player", id)
	
	if not purchased:
		return
		
	match id:
		"worker":
			emit_signal("worker_purchased", "player")
	

func set_context(context: String, structure_id: String = "", force_open: bool = false) -> void:
	if (not force_open and last_action == context) or context == NULL_CONTEXT:
		hide()
		last_action = NULL_CONTEXT
		_current_structure_id = ""
		return
	if structure_id != "":
		_current_structure_id = structure_id
	show()
	var entries: Array[Dictionary] = []
	match context:
		HARVESTING_CONTEXT:
			entries = harvesting_actions
		BUILDING_CONTEXT:
			entries = building_actions
		BASE_CONTEXT:
			entries = base_actions
		_:
			entries = []
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
	_refresh_entries_cost()
	last_action = context
			
func _clear_entries() -> void:
	_grid.columns = 1
	_current_entries.clear()
	for child in _grid.get_children():
		child.hide()
	
func _get_cost_for_core_action_id(id: String) -> Dictionary:
	if not _game:
		return {}
	return _game.get_core_cost_for_team("player", id)
	
func _get_cost_for_structure_upgrade_action_id(structure_id: String, id: String) -> Dictionary:
	if not _game:
		return {}
	return _game.get_structure_upgrade_cost_for_team("player", structure_id, id)

func _refresh_entries_cost(_player_resources: Dictionary = {}) -> void:
	if last_action == HARVESTING_CONTEXT:
		return
	if not _current_entries.size() > 0:
		return
		
	for e in _current_entries.keys():
		var entry: Dictionary = _current_entries.get(e)
		if not entry.get("definition").has("cost_type"):
			continue
		
		var cost_type: String = entry.get("definition").get("cost_type")
		var cost_id: String = entry.get("definition").get("id")
		var cost_info: Dictionary = _game.get_core_cost_for_team("player", cost_id) if cost_type == "core" else _game.get_structure_upgrade_cost_for_team("player", _current_structure_id, cost_id)
		var can_afford: bool = _game.can_afford_core_for_team("player", cost_id) if cost_type == "core" else false
		var button: TextureButton = entry.get("button_node") if entry.has("button_node") else entry.get("button").get_node_or_null("TextureButton")
		if button:
			button.disabled = not can_afford
		_update_cost_labels(entry.get("button").get_node("CostContainer"), cost_info)
			

			
		
	
	
func _add_entry(definition: Dictionary) -> Dictionary:
	var container: VBoxContainer = VBoxContainer.new()
	container.custom_minimum_size = Vector2(200, 120)
	container.alignment = BoxContainer.ALIGNMENT_CENTER
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var tex_butt: TextureButton = TextureButton.new()
	tex_butt.name = "TextureButton"
	tex_butt.custom_minimum_size = Vector2(120, 120)
	tex_butt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tex_butt.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	tex_butt.focus_mode = Control.FOCUS_NONE
	tex_butt.tooltip_text = definition.get("description", "")
	
	var icon_base: Texture2D = ImageLibrary.get_icon(definition.get("icon").get("base"))
	var icon_hover: Texture2D = ImageLibrary.get_icon(definition.get("icon").get("hover"))
	tex_butt.texture_normal = icon_base
	tex_butt.texture_hover = icon_hover	
	
	if definition.get("icon").has("disabled"):
		var icon_disabled: Texture2D = ImageLibrary.get_icon(definition.get("icon").get("disabled"))
		tex_butt.texture_disabled = icon_disabled
	
	
	if definition.has("press_signal"):
		tex_butt.pressed.connect(func() -> void:
			definition["press_signal"].call()
		)

	var label: Label = Label.new()
	label.text = definition.get("label", "unknown")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(96, 20)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.set_theme_type_variation("MediumLabel")
	label.set_anchor(SIDE_TOP, 1.0)
	container.add_child(label)
	container.add_child(tex_butt)
	
	if definition.has("cost_type"):
		var cost_container: VBoxContainer = VBoxContainer.new()
		cost_container.name = "CostContainer"
		cost_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cost_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
		cost_container.set_anchors_preset(Control.PRESET_CENTER_TOP)
		container.add_child(cost_container)
		var cost_id: String = definition.get("id")
		var cost_type: String = definition.get("cost_type")
		var cost_info: Dictionary = _game.get_core_cost_for_team("player", cost_id) if cost_type == "core" else _game.get_structure_upgrade_cost_for_team("player", _current_structure_id, cost_id)
		_update_cost_labels(cost_container, cost_info)
		var can_afford: bool = _game.can_afford_core_for_team("player", cost_id) if cost_type == "core" else false
		tex_butt.disabled = not can_afford
	
	_entries_cache[definition.get("id")] = {
		"button": container,
		"button_node": tex_butt,
		"definition": definition
	}
	
	return {
		"button": container,
		"button_node": tex_butt,
		"definition": definition
	}

func _update_cost_labels(cost_container: VBoxContainer, cost_info: Dictionary) -> void:
	for ci in cost_info.keys():
		var existing_cost_label: Variant = cost_container.get_node_or_null(ci)
		if existing_cost_label:
			existing_cost_label.update_cost(cost_info[ci])
		else:
			var new_cost_label: CostLabel = _cost_label_scene.instantiate()
			new_cost_label.name = ci
			cost_container.add_child(new_cost_label)
			new_cost_label.type = ci
			new_cost_label.amount = cost_info[ci]
			new_cost_label.label_size = "medium"
		
