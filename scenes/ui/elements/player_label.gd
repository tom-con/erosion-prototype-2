extends HBoxContainer
class_name PlayerLabel

@onready var shader: Shader = load("res://scenes/vfx/shaders/team_color.gdshader")
@onready var tex_rect: TextureRect = $TextureRect
@onready var label: Label = $Label

var player_name: String = ""
var player_color: Color

func _ready() -> void:
	if not player_name or not player_color:
		print("PlayerLabel failed to create")
	label.text = player_name.to_upper()
	tex_rect.material = ShaderMaterial.new()
	tex_rect.material.shader = shader
	tex_rect.material.set_shader_parameter("team_color", player_color)
