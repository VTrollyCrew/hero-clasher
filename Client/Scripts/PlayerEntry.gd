# This is the player entry script
# This is used to recognize the player who has entered into the waiting room
# Host player can kick the player who is in the room if needed. The other players are not allowed to that
# This allows to switch the players' (including host) ready status if needed. This is important to the room management
# This script is attached to the PlayerEntry.tscn scene

# Codebase is referencing on multiple sources
# Source 1: https://docs.godotengine.org (For scene GUI container, scene tree management, button management, etc). This is the official documentation
# Source 2: Deepseek AI (For reference code)

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
	ready_label.text = "Player Ready" if ready else "Player Not Ready"
	kick_button.visible = show_kick

func set_empty(role: String):
	name_label.text = "Empty"
	role_label.text = role
	ready_label.text = ""
	kick_button.visible = false

func _on_kick_button_pressed() -> void:
	kick_requested.emit()
