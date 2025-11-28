extends Control
class_name CostLabel

const SIZES: Dictionary = {
	"small": {
		"self": Vector2(96, 24),
		"texture": Vector2(24, 24),
		"label": Vector2(72, 24),
		"type_override": "SmallLabel"
	},
	"medium": {
		"self": Vector2(128, 48),
		"texture": Vector2(48, 48),
		"label": Vector2(80, 48),
		"type_override": "MediumLabel"
	},
}

const TYPE_TO_TEXTURE: Dictionary = {
	"wood": "wood_icon",
	"stone": "stone_icon",
	"iron": "iron_icon",
	"food": "food_icon"
}

var label_size: String = "small"
var type: String = "type"
var amount: int = 0

@onready var _label: Label = $Label

func _ready() -> void:
	_initialize_label()

func _initialize_label() -> void:
	var icon_texture: Texture2D = ImageLibrary.get_icon(TYPE_TO_TEXTURE.get(type))
	$TextureRect.texture = icon_texture
	update_cost(amount)
	_set_label_size(label_size)

func update_cost(amt: int) -> void:
	_label.text = "%d" % amt
	
	
func _set_label_size(lbl_size: String) -> void:
	if not SIZES.has(lbl_size):
		print("CostLabel size not valid")
	else:
		self.custom_minimum_size = SIZES.get(lbl_size).get("self")
		$TextureRect.custom_minimum_size = SIZES.get(lbl_size).get("texture")
		_label.custom_minimum_size = SIZES.get(lbl_size).get("label")
		_label.set_theme_type_variation(SIZES.get(lbl_size).get("type_override"))
