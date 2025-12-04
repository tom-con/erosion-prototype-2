extends Node2D
class_name Stockpile

@export var is_player: bool = true # Must be set prior to addition to scene tree
@export var team_id: String = "" # Must be set prior to addition to scene tree
var team_color: Color = Color.WHITE

@export var width_in_tiles = 1
@export var height_in_tiles = 1

@export var max_health: int = 100

var shader: Shader = preload("res://scenes/vfx/shaders/team_color.gdshader")

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _images: ImageLibrary = get_node("/root/ImageLibrary")
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
	_apply_sprite()

func _apply_sprite() -> void:
	if not _images.has_building("stockpile"):
		print("Missing stockpile texture in Image Library")
		return
	_sprite.texture = _images.get_building("stockpile")
	_apply_team_color()

func _apply_team_color() -> void:
	var game_team_color: Color = _game.get_team_color(team_id)
	var settable_team_color: Color = game_team_color if game_team_color else team_color
	if _sprite:
		_sprite.material = ShaderMaterial.new()
		_sprite.material.shader = shader
		_sprite.material.set_shader_parameter("team_color", settable_team_color)
