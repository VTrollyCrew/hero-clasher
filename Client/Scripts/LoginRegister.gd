# LoginScene.gd
extends Control

@onready var email_input = $NinePatchRect/VBoxContainer/UsernameLineEdit
@onready var password_input = $NinePatchRect/VBoxContainer/PasswordLineEdit

func _on_register_button_pressed():
	var email = email_input.text
	var password = password_input.text
	
	# 1. Check Email
	if not AuthManager.is_valid_email(email):
		AuthManager.show_message("Please enter a valid email address.")
		return
		
	# 2. Check Password Strength
	var password_issue = AuthManager.is_strong_password(password)
	if password_issue != "":
		AuthManager.show_message(password_issue)
		return
	
	if email.is_empty() or password.length() < 8:
		print("Please enter a valid email and a password (min 8 chars).")
		return
		
	AuthManager.register_user(email, password)


func _on_log_in_button_pressed() -> void:
	print("--- Button Pressed! ---") # <--- ADD THIS
	var email = email_input.text
	var password = password_input.text
	print("Attempting to login with: ", email) # <--- ADD THIS
	
	if email.is_empty() or password.is_empty():
		AuthManager.show_message("Please fill in all fields.")
		return
	
	AuthManager.login_user(email, password)
