extends Node


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
			"color": team_color
		}

func get_teams() -> Array:
	return teams.keys()

func get_resource_pool_for_team_id(team_key: String) -> Dictionary:
	if not teams.has(team_key):
		return {}
	return teams.get(team_key).get("resources")

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
