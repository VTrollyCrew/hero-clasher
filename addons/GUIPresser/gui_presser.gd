@tool
extends Node

const BUTTONS: Array[int] = [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]

signal hover_state_changed(state: bool)
signal pressed_state_changed(state: bool, button: int)
signal activated(button: int)

@export var disabled: bool = false : set = _set_disabled

var parent: Control = null

var pressed_arr: Array[bool] = [false, false, false]
var hovered: bool = false

func _set_disabled(state: bool) -> void:
	disabled = state
	if disabled: _disconnect_parent()
	else: _connect_parent()

func _disconnect_parent() -> void:
	if parent:
		if parent.gui_input.is_connected(_gui_processing):
			parent.gui_input.disconnect(_gui_processing)
		if parent.mouse_entered.is_connected(_hover_state_changed):
			parent.mouse_entered.disconnect(_hover_state_changed)
		if parent.mouse_exited.is_connected(_hover_state_changed):
			parent.mouse_exited.disconnect(_hover_state_changed)

func _connect_parent() -> void:
	if parent:
		if !parent.gui_input.is_connected(_gui_processing):
			parent.gui_input.connect(_gui_processing)
		if !parent.mouse_entered.is_connected(_hover_state_changed):
			parent.mouse_entered.connect(_hover_state_changed.bind(true))
		if !parent.mouse_exited.is_connected(_hover_state_changed):
			parent.mouse_exited.connect(_hover_state_changed.bind(false))

func _get_configuration_warnings() -> PackedStringArray:
	var _parent = get_parent()
	if _parent && _parent is Control : return [] 
	return ["A parent of the Control class is required"]

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PARENTED:
			var _parent = get_parent()
			if !_parent || !(_parent is Control):
				parent = null
				update_configuration_warnings()
				return
			parent = _parent
			if !disabled: _connect_parent()
		NOTIFICATION_UNPARENTED:
			if parent:
				_disconnect_parent()
				parent = null

func _hover_state_changed(value: bool) -> void:
	if hovered != value:
		hovered = value
		emit_signal("hover_state_changed", value)

func _gui_processing(event: InputEvent) -> void:
	if event is InputEventMouseButton && BUTTONS.has(event.button_index):
		if event.pressed && !hovered: return
		var arr_index: int = event.button_index - 1
		if pressed_arr[arr_index] == event.pressed: return
		pressed_arr[arr_index] = event.pressed
		emit_signal("pressed_state_changed", event.pressed, event.button_index)
		if !event.pressed && hovered: emit_signal("activated", event.button_index)
