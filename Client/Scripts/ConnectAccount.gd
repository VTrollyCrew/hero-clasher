extends Control

@onready var email_input = $NinePatchRect/VBoxContainer/UsernameLineEdit
@onready var password_input = $NinePatchRect/VBoxContainer/PasswordLineEdit

func _on_log_in_button_pressed() -> void:
	var email = email_input.text
	var password = password_input.text
	
	# Reuse the validation logic from AuthManager
	if not AuthManager.is_valid_email(email):
		AuthManager.show_message("Connection Error", "Please enter a valid Vtrolly email.")
		return
		
	if password.is_empty():
		AuthManager.show_message("Connection Error", "Please enter your Vtrolly password.")
		return
	
	# Make the call
	AuthManager.connect_vtrolly_account(email, password)
