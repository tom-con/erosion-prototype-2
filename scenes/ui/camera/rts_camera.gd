extends Camera2D

@export var pan_speed: float = 1300             # base panning speed in px/s
@export var fast_multiplier: float = 1.8          # hold Shift ("cam_fast") to go faster
@export var edge_size_px: float = 18.0            # edge band width for edge-scroll
@export var edge_scroll_strength: float = 1.0     # 1.0 = full speed at the edge

@export var move_lerp: float = 50.0               # pan lerp snappiness
@export var zoom_step: float = 1.3              # wheel zoom factor per step
@export var zoom_min: float = 0.4                # smaller = closer in
@export var zoom_max: float = 3                # larger = farther out
@export var zoom_lerp: float = 12.0               # zoom lerp snappiness
@export var pan_gesture_zoom_sensitivity: float = 0.08 # scales trackpad pinch delta

@export var map_world_rect: Rect2 = Rect2(Vector2.ZERO, Vector2(4096, 2304))
@export var tilemap_path: NodePath = "/root/Main/TerrainMap"

@export var use_world_clamp: bool = false         # OFF by default so pan/drag always work
#@export var debug_overlay: bool = false           # show a tiny HUD with camera state

var _target_pos: Vector2 = Vector2.ZERO
var _target_zoom: float = 1.0
var _dragging: bool = false
var _drag_anchor_world: Vector2 = Vector2.ZERO
var _viewport_size: Vector2 = Vector2.ZERO
var _world_bounds: Rect2 = Rect2()


#var _dbg_label: Label = null

func _ready() -> void:
	make_current()
	_configure_world_bounds()
	_target_pos = global_position
	_target_zoom = zoom.x
	_viewport_size = get_viewport_rect().size
	
	get_viewport().size_changed.connect(_on_viewport_size_changed)


func _configure_world_bounds() -> void:
	var terrain_map: TerrainMap = get_node(tilemap_path)
	if !terrain_map or !terrain_map is TerrainMap:
		print("Missing TerrainMap at given path")
		return
	else:
		var world_rect: Rect2i = terrain_map.get_world_rect()
		_world_bounds = world_rect
	
func _on_viewport_size_changed() -> void:
	_viewport_size = get_viewport_rect().size
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("cam_drag"):
		_dragging = true
		_drag_anchor_world = _mouse_world()
		get_viewport().set_input_as_handled()
	elif event.is_action_released("cam_drag"):
		_dragging = false
		get_viewport().set_input_as_handled()
		
	if event.is_action_pressed("zoom_in"):
		_apply_zoom_step(-1.0)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("zoom_out"):
		_apply_zoom_step(1.0)
		get_viewport().set_input_as_handled()
	elif event is InputEventPanGesture:
		_apply_pan_gesture_zoom(event as InputEventPanGesture)

func _apply_zoom_step(direction: float) -> void:
	if direction < 0.0:
		_target_zoom = max(zoom_min, _target_zoom / (zoom_step * 4))
	else:
		_target_zoom = min(zoom_max, _target_zoom * (zoom_step * 4))

func _apply_pan_gesture_zoom(pan_event: InputEventPanGesture) -> void:
	if pan_event.delta.y == 0.0:
		return

	var gesture_steps: float = pan_event.delta.y * pan_gesture_zoom_sensitivity
	var zoom_factor: float = pow(zoom_step, gesture_steps)
	_target_zoom = clamp(_target_zoom * zoom_factor, zoom_min, zoom_max)
	get_viewport().set_input_as_handled()

func _physics_process(delta: float) -> void:
	var desired_move: Vector2 = Vector2.ZERO
	
	var axis_h: int = int(Input.is_action_pressed("cam_right")) - int(Input.is_action_pressed("cam_left"))
	var axis_v: int = int(Input.is_action_pressed("cam_down")) - int(Input.is_action_pressed("cam_up"))
	var input_vec: Vector2 = Vector2(axis_h, axis_v)
	if input_vec.length() > 0.0:
		input_vec = input_vec.normalized()
	desired_move += input_vec
	
	var speed: float = pan_speed
	if Input.is_action_pressed("cam_fast"):
		speed *= fast_multiplier
	speed /= max(zoom.x, 0.0001)
	
	var move_delta: Vector2 = desired_move * speed * delta
	
	if _dragging:
		var new_mouse_world: Vector2 = _mouse_world()
		var drag_delta: Vector2 = _drag_anchor_world - new_mouse_world
		_target_pos += drag_delta
		_drag_anchor_world = new_mouse_world
	else:
		_target_pos += move_delta
		
	var lerp_target: Vector2 = _target_pos
	if use_world_clamp:
		lerp_target = _clamp_to_bounds(_target_pos, _target_zoom)
	global_position = global_position.lerp(lerp_target, 1.0 - exp(-move_lerp * delta))
	
	var current_zoom: float = zoom.x
	var z: float = lerp(current_zoom, _target_zoom, 1.0 - exp(-zoom_lerp * delta))
	zoom = Vector2(z, z)
	
	if use_world_clamp:
		global_position = _clamp_to_bounds(global_position, zoom.x)

func _mouse_world() -> Vector2:
	var screen: Vector2 = get_viewport().get_mouse_position()
	return get_canvas_transform().affine_inverse() * screen
	
func _clamp_to_bounds(pos: Vector2, zoom_value: float) -> Vector2:
	if zoom_value <= 0.0 or is_nan(zoom_value):
		return pos
	
	var half: Vector2 = (_viewport_size * 0.5) * zoom_value
	
	var min_x: float = _world_bounds.position.x + half.x
	var max_x: float = _world_bounds.position.x + _world_bounds.size.x - half.x
	var min_y: float = _world_bounds.position.y + half.y
	var max_y: float = _world_bounds.position.y + _world_bounds.size.y - half.y
	
	if min_x <= max_x:
		pos.x = clamp(pos.x, min_x, max_x)
	if min_y <= max_y:
		pos.y = clamp(pos.y, min_y, max_y)
	
	return pos
