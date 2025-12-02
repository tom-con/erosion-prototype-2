extends PanelContainer
class_name PlayerPanel

var _player_label: PackedScene = preload("res://scenes/ui/elements/player_label.tscn")

@onready var _game: Game = get_node_or_null("/root/Game")
@onready var _vbox: VBoxContainer = get_node("MarginContainer/VBoxContainer")

func _ready() -> void:
	pass
		
	
		
func draw_players() -> void:
	var teams: Array = _game.get_teams()
	
	for t in teams:
		var team_player_label: PlayerLabel = _player_label.instantiate()
		team_player_label.player_name = t
		team_player_label.player_color = _game.get_team_color(t)
		_vbox.add_child(team_player_label)
		
