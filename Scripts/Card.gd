extends Node2D

signal hovered
signal hovered_off

var starting_position

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# This makes sure that all carda a child of the CardManager. If not, this will emit an fatal error
	get_parent().connect_card_signals(self)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# This will manage the hover logic
func _on_area_2d_mouse_entered() -> void:
	emit_signal("hovered", self)

# This will manage the exit hover logic
func _on_area_2d_mouse_exited() -> void:
	emit_signal("hovered_off", self)
