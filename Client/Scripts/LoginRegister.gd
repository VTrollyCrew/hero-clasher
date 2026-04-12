# This is the Log in and Register client side script
# This script collects the login and registration data from the scene and pass it down to the AuthManager.gd in the server side to handle the data
# This is attached to the LogInRegister.tscn scene

# Codebase is referencing on multiple sources
# Source 1: https://docs.godotengine.org (For scene GUI container, scene tree management, button management, etc). This is the official documentation
# Source 2: Deepseek AI (For reference code)

extends Control

@onready var email_input = $NinePatchRect/VBoxContainer/UsernameLineEdit
@onready var password_input = $NinePatchRect/VBoxContainer/PasswordLineEdit

func _on_register_button_pressed():
	var email = email_input.text
	var password = password_input.text
	
	# 1. Check Email
	if not AuthManager.is_valid_email(email):
		AuthManager.show_message("Registration Error", "Please enter a valid email address.")
		return
		
	# 2. Check Password Strength
	var password_issue = AuthManager.is_strong_password(password)
	if password_issue != "":
		AuthManager.show_message("Registration Error", password_issue)
		return
	
	# 3. Check valid values are entered to email or password
	if email.is_empty() or password.length() < 8:
		AuthManager.show_message("Registration Error", "Please enter a valid email and a password (min 8 chars).")
		return
		
	AuthManager.register_user(email, password)


func _on_log_in_button_pressed() -> void:
	var email = email_input.text
	var password = password_input.text
	
	if email.is_empty() or password.is_empty():
		AuthManager.show_message("Login Error", "Please fill in all fields.")
		return
	
	AuthManager.login_user(email, password)
