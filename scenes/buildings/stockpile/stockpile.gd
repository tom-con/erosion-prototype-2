extends Node2D
class_name Stockpile

@export var is_player: bool = true # Must be set prior to addition to scene tree
@export var team_id: String = "" # Must be set prior to addition to scene tree
@export var team_color: Color = Color.WHITE

@export var width_in_tiles = 1
@export var height_in_tiles = 1

@export var max_health: int = 100

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _game: Node = get_node("/root/Game")

var health: int

func _ready() -> void:
	team_id = team_id.strip_edges()
	if team_id == "":
		print("Stockpile: Bad instantiation, team_id must be set")
		return
	add_to_group("buildings")
	add_to_group("dropoffs")
	health = max_health
	_apply_team_color()


func _apply_team_color() -> void:
	var game_team_color: Color = _game.get_team_color(team_id)
	var settable_team_color: Color = game_team_color if game_team_color else team_color
	if _sprite and _sprite.material:
		_sprite.material = ShaderMaterial.new()
		_sprite.material.set_shader_parameter("team_color", settable_team_color)
