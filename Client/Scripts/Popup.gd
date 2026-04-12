# This is the popup box modal
# This is a reusable popup container for status, error messages to be displayed in the game

extends CanvasLayer

@onready var message_label = $PanelContainer/VBoxContainer/MessageLabel

func set_message(MainText: String, MessageText: String):
	$PanelContainer/VBoxContainer/MainLabel.text = MainText
	$PanelContainer/VBoxContainer/MessageLabel.text = MessageText

func _on_exit_button_pressed() -> void:
	queue_free() # Closes the popup
