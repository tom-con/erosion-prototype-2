extends Control
class_name CostLabel

var _type_to_texture: Dictionary = {
	"wood": "wood_icon",
	"stone": "stone_icon",
	"iron": "iron_icon",
	"food": "food_icon"
}

func _ready() -> void:
	self.custom_minimum_size = Vector2(96, 20)

func set_cost(type: String, amount: int) -> void:
	var icon_texture: Texture2D = ImageLibrary.get_icon(_type_to_texture.get(type))
	$TextureRect.texture = icon_texture
	$Label.text = "%d" % amount
