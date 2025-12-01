extends AnimatedSprite2D
class_name Worker

@export var move_speed: float = 70.0
@export var resource_arrive_distance: float = 28.0
@export var deposit_distance: float = 32.0
@export var gather_duration: float = 2.25
@export var search_radius_tiles: int = 100
@export var harvest_resources: PackedStringArray = PackedStringArray(["wood", "stone", "food", "iron"])
@export var backpack_capacity: int = 100

var home_base: BaseBuilding = null
var team_id: String = ""
var is_player: bool = true
var team_color: Color = Color.WHITE

const STATE_IDLE := 0
const STATE_MOVING_TO_RESOURCE := 1
const STATE_HARVESTING := 2
const STATE_RETURNING := 3

var _backpack: Dictionary = {
	"wood": 0,
	"stone": 0,
	"food": 0,
	"iron": 0
}

var _state: int = STATE_IDLE
var _target_tile: Vector2i = Vector2i(-1, -1)
var _gather_timer: float = 0.0
var _carried_type: String = ""
var _exception_refresh_timer: float = 0.0

func _get_carried_amount() -> int:
	var total: int = 0
	for r in _backpack.keys():
		total += _backpack[r]
	return total

func _can_harvest() -> bool:
	return _get_carried_amount() < backpack_capacity
