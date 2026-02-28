# LoginScene.gd
extends Control

@onready var email_input = $CenterContainer/VBoxContainer/EmailInput
@onready var password_input = $CenterContainer/VBoxContainer/PasswordInput

func _on_login_button_pressed():
	print("--- Button Pressed! ---") # <--- ADD THIS
	var email = email_input.text
	var password = password_input.text
	print("Attempting to login with: ", email) # <--- ADD THIS
	
	AuthManager.login_user(email, password)

func _on_register_button_pressed():
	var email = email_input.text
	var password = password_input.text
	
	if email.is_empty() or password.length() < 8:
		print("Please enter a valid email and a password (min 8 chars).")
		return
		
	AuthManager.register_user(email, password)
