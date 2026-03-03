extends CanvasLayer

@onready var message_label = $PanelContainer/VBoxContainer/MessageLabel

func set_message(text: String):
	$PanelContainer/VBoxContainer/MessageLabel.text = text

func _on_exit_button_pressed() -> void:
	queue_free() # Closes the popup
