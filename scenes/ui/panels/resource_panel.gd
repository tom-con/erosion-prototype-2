extends PanelContainer
class_name ResourcePanel

@onready var _cost_label_scene = load("res://scenes/ui/elements/cost_label.tscn")
@onready var _game: Node = get_node_or_null("/root/Game")
@onready var _container: HBoxContainer = get_node("MarginContainer/HBoxContainer")

var _resources: Dictionary = {}

func _ready() -> void:
	if _game:
		_game.player_resources_changed.connect(_render_resources_for_player)
		
	
func initialize_resources() -> void:
	var resource_pool: Dictionary = _game.get_resource_pool_for_team_id("player")
	_render_resources_for_player(resource_pool)
	
func _render_resources_for_player(resource_pool: Dictionary) -> void:
	print(resource_pool)
	for r in resource_pool.keys():
		var amount: int = resource_pool[r]
		var cost_label: CostLabel = _resources.get(r) if _resources.has(r) else _cost_label_scene.instantiate()
		cost_label.label_size = "medium"
		cost_label.type = r
		
		if not _resources.has(r):
			cost_label.amount = amount
			_resources[r] = cost_label
			_container.add_child(cost_label)
		else:
			cost_label.update_cost(amount)
		
		
		
