extends PopupPanel

var deck_data: Dictionary
signal edit_deck(deck_data)
signal delete_deck(deck_data)

func set_deck(data: Dictionary):
	deck_data = data

func _on_edit_deck_button_pressed() -> void:
	emit_signal("edit_deck", deck_data)
	hide()


func _on_delete_deck_button_pressed() -> void:
	emit_signal("delete_deck", deck_data)
	hide()
