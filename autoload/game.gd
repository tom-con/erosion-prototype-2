extends Node

signal player_resources_changed(resources: Dictionary)

var time_elapsed: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _selected_colors: PackedColorArray = []

const COLOR_CHOICES: PackedColorArray = [Color.AQUA, Color.BLUE, Color.BROWN, Color.CHARTREUSE, Color.CRIMSON, Color.DARK_ORANGE, Color.DEEP_PINK, Color.GOLD, Color.INDIGO, Color.LIGHT_GRAY, Color.PALE_TURQUOISE]
const INITIAL_RESOURCES: Dictionary = {
	"wood": 0,
	"stone": 0,
	"food": 0,
	"iron": 0
}

const INITIAL_CORE_COSTS: Dictionary = {
	"archer_barracks": {
		"wood": 2000,
		"stone":1200,
		"food": 400	
	},
	"spearman_barracks": {
		"wood": 800,
		"stone": 800,
		"food": 200
	},
	"stockpile": {
		"wood": 400
	},
	"worker": {
		"food": 100
	}
}

const INITIAL_STRUCTURE_UPGRADE_COSTS: Dictionary = {
	"spawn_rate": {
		"wood": 300,
		"stone": 300,
		"food": 100
	}
}

var teams: Dictionary = {}

func _ready() -> void:
	_rng.randomize()

func _physics_process(delta: float) -> void:
	time_elapsed += delta

func add_team(team_key: String) -> void:
	if not teams.has(team_key):
		var team_color: Color = _select_color_for_actor()
		teams[team_key] = {
			"resources": INITIAL_RESOURCES.duplicate(),
			"color": team_color,
			"costs": {
				"core": INITIAL_CORE_COSTS.duplicate(),
				"structures": {
					"base": INITIAL_STRUCTURE_UPGRADE_COSTS.duplicate()
				}
			},
			"purchased": {
				"archer_barracks": 0,
				"spearman_barracks": 0,
				"stockpile": 0,
				"worker": 0
			}
		}

func get_teams() -> Array:
	return teams.keys()

func get_resource_pool_for_team_id(team_key: String) -> Dictionary:
	if not teams.has(team_key):
		return {}
	return teams.get(team_key).get("resources")
	
func add_resources(team_key: String, resources: Dictionary) -> void:
	if teams.has(team_key):
		for r in resources.keys():
			teams[team_key]["resources"][r] = teams[team_key]["resources"][r] + resources[r]
		if team_key == "player":
			emit_signal("player_resources_changed", teams[team_key]["resources"])
		

func get_team_color(team_key: String) -> Color:
	if not teams.has(team_key):
		return Color.WHITE
	return teams.get(team_key).get("color")

func _select_color_for_actor() -> Color:
	var i: float = _rng.randf()
	var color_choices = Array(COLOR_CHOICES)
	var available_colors: PackedColorArray = color_choices.filter(func(c: Color): return not _selected_colors.has(c))
	var index: int = floor(i * available_colors.size())
	var selected_color: Color = available_colors[index]
	_selected_colors.append(selected_color)
	return selected_color
	
func get_core_cost_for_team(team_key: String, id: String) -> Dictionary:
	if not teams.get(team_key, {}).get("costs", {}).get("core", {}).get(id):
		return {}
	return teams.get(team_key).get("costs").get("core").get(id)

func get_structure_upgrade_cost_for_team(team_key: String, structure_id: String, upgrade_id: String) -> Dictionary:
	if not teams.get(team_key, {}).get("costs", {}).get("structures", {}).get(structure_id):
		teams[team_key]["costs"]["structures"][structure_id] = INITIAL_STRUCTURE_UPGRADE_COSTS.duplicate()
	if not teams.get(team_key, {}).get("costs", {}).get("structures", {}).get(structure_id, {}).get(upgrade_id):
		return {}
	return teams.get(team_key).get("costs").get("structures").get(structure_id).get(upgrade_id)
