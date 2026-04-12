# This is the the location where the VTrolly account details are connected from the client side
# This connects the tables from the VTrolly MongoDB with the Pocketbase database
# The data is transferred to the AuthManager script in the server side setup
# This script is connected to the ConnectToVTrolly.tscn scene

# This is a common pattern to transfer information

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
