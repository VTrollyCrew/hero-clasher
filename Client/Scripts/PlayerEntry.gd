extends HBoxContainer

signal kick_requested

@onready var name_label = $NameLabel
@onready var role_label = $RoleLabel
@onready var ready_label = $ReadyLabel
@onready var kick_button = $KickButton

func setup(player_data, role: String, show_kick: bool, ready: bool):
	# You can fetch username from AuthManager or a separate cache
	# player_data can be string (ID) or dictionary (user record)
	if typeof(player_data) == TYPE_DICTIONARY:
		name_label.text = player_data.get("username", player_data.get("id", "Unknown"))
	else:
		name_label.text = player_data
	role_label.text = role
	ready_label.text = "✔" if ready else "◯"
	kick_button.visible = show_kick

func set_empty(role: String):
	name_label.text = "Empty"
	role_label.text = role
	ready_label.text = ""
	kick_button.visible = false

func _on_kick_button_pressed() -> void:
	kick_requested.emit()
