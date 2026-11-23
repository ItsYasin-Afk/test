extends Control
class_name VirtualStick

signal value_changed(value: Vector2)

@export var dead_zone: float = 0.12
var _finger_index: int = -1
var _value: Vector2 = Vector2.ZERO
var _knob_offset: Vector2 = Vector2.ZERO
var _radius: float = 78.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()

func get_value() -> Vector2:
	return _value

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _finger_index == -1:
			_finger_index = event.index
			_update_from_position(event.position)
		elif not event.pressed and event.index == _finger_index:
			_finger_index = -1
			_set_value(Vector2.ZERO)
	elif event is InputEventScreenDrag and event.index == _finger_index:
		_update_from_position(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _finger_index == -1:
			_finger_index = 0
			_update_from_position(event.position)
		elif not event.pressed and _finger_index == 0:
			_finger_index = -1
			_set_value(Vector2.ZERO)
	elif event is InputEventMouseMotion and _finger_index == 0 and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_update_from_position(event.position)

func _update_from_position(local_position: Vector2) -> void:
	var center := size * 0.5
	var offset := local_position - center
	if offset.length() > _radius:
		offset = offset.normalized() * _radius
	_knob_offset = offset
	var next_value := offset / _radius
	if next_value.length() < dead_zone:
		next_value = Vector2.ZERO
	_set_value(next_value)
	queue_redraw()

func _set_value(next_value: Vector2) -> void:
	_value = next_value
	if _value == Vector2.ZERO:
		_knob_offset = Vector2.ZERO
	value_changed.emit(_value)
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	draw_circle(center, _radius, Color(0.08, 0.12, 0.16, 0.58))
	draw_arc(center, _radius, 0.0, TAU, 48, Color(0.65, 0.78, 0.82, 0.7), 3.0)
	draw_circle(center + _knob_offset, 30.0, Color(0.55, 0.78, 0.82, 0.78))
	draw_arc(center + _knob_offset, 30.0, 0.0, TAU, 32, Color(0.9, 0.97, 1.0), 2.0)
