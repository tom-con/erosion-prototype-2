extends Node2D
class_name SelectionHighlight

@export var line_color: Color = Color(1.0, 0.9, 0.2, 0.95)
@export var line_width: float = 3.0

var _mode: String = ""
var _circle_center: Vector2 = Vector2.ZERO
var _circle_radius: float = 0.0
var _rect: Rect2 = Rect2()
var _edge_segments: Array = []

func _ready() -> void:
	position = Vector2.ZERO
	z_index = 1000
	hide()
	
func show_circle(center: Vector2, radius: float) -> void:
	_mode = "circle"
	_circle_center = to_local(center)
	_circle_radius = radius
	show()
	queue_redraw()


func show_rect(rect: Rect2) -> void:
	_mode = "rect"
	_rect = Rect2(to_local(rect.position), rect.size)
	_edge_segments.clear()
	show()
	queue_redraw()

func show_edges(segments: Array) -> void:
	_mode = "edges"
	_edge_segments = []
	for segment in segments:
		var pts: PackedVector2Array = segment
		var local: PackedVector2Array = PackedVector2Array()
		for p in pts:
			local.append(to_local(p))
		_edge_segments.append(local)
	show()
	queue_redraw()

func hide_highlight() -> void:
	_mode = ""
	hide()
	queue_redraw()

func _draw() -> void:
	if _mode == "circle":
		draw_arc(_circle_center, _circle_radius, 0.0, TAU, 64, line_color, line_width)
	elif _mode == "rect":
		draw_rect(_rect, line_color, false, line_width)
	elif _mode == "edges":
		for segment in _edge_segments:
			var pts: PackedVector2Array = segment
			if pts.size() >= 2:
				draw_line(pts[0], pts[1], line_color, line_width)
