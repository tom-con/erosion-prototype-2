extends Node


var time_elapsed: float = 0.0
var team_colors: Dictionary = {}
var resource_pools: Dictionary = {}
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _selected_colors: PackedColorArray = []

const COLOR_CHOICES: PackedColorArray = [Color.AQUA, Color.BLUE, Color.BROWN, Color.CHARTREUSE, Color.CRIMSON, Color.DARK_ORANGE, Color.DEEP_PINK, Color.GOLD, Color.INDIGO, Color.LIGHT_GRAY, Color.PALE_TURQUOISE]

func _ready() -> void:
	_rng.randomize()

func _physics_process(delta: float) -> void:
	time_elapsed += delta

func get_team_color(team_key: String) -> Color:
	if team_colors.has(team_key):
		return team_colors[team_key]
	var color: Color = _select_team_color()
	team_colors[team_key] = color
	return color

func _select_team_color() -> Color:
	var i: float = _rng.randf()
	var color_choices = Array(COLOR_CHOICES)
	var available_colors: PackedColorArray = color_choices.filter(func(c: Color): return not _selected_colors.has(c))
	var index: int = floor(i * available_colors.size())
	var selected_color: Color = available_colors[index]
	_selected_colors.append(selected_color)
	return selected_color
