# This is the authentication manager script
# There are multiple tasks handled in this section

# 1. This manages the user session cookies which are saved in the game user://sessions.cfg file
# 2. This manages the pocketbase database connection and the VTrolly user database connection
# 3. Pocketbase acts as the hot database for the active data in the game and the VTrolly MongoDB database acts as a cold database to store archived data and the user data for reference
# 4. All logins, registrations and syncs are managed in this server script
# 5. All session management including data loading, deletion and read functions are done through here
# 6. All data validations such as user connections, email, password valications are done through here

# Codebase is referencing on multiple sources
# Source 1: https://docs.godotengine.org/en/stable/tutorials/networking/http_request_class.html (For http requests, server data transfering, and cookie data management). This is the official documentation
# Source 2: Deepseek AI (For reference code)

extends Node

const SAVE_PATH = "user://session.cfg"
const SESSION_EXPIRY_SECONDS = 14 * 24 * 60 * 60 # 14 days

signal user_data_updated

var popup_scene = preload("res://Client/Scenes/UI/PopupMessage.tscn")

# The address where your backend (PocketBase) is running
const BACKEND_URL = "http://127.0.0.1:8090"
var http_request : HTTPRequest

# Store the token after logging in
var is_vtrolly_connected : bool = false
var is_logged_in : bool = false
var username : String = ""
var vcoins : int = 0
var auth_token = ""
var user_id = ""

func _ready():
	http_request = HTTPRequest.new()
	add_child(http_request)
	load_session()

# Sends login credentials to the backend
func login_user(email, password):
	var body = JSON.stringify({
		"identity": email,
		"password": password
	})
	var headers = ["Content-Type: application/json"]
	
	# We use the pocketbase auth endpoint
	http_request.request(BACKEND_URL + "/api/collections/users/auth-with-password", headers, HTTPClient.METHOD_POST, body)
	
	# Connect the signal to handle the response
	if not http_request.request_completed.is_connected(_on_login_completed):
		http_request.request_completed.connect(_on_login_completed)

func _on_login_completed(result, response_code, headers, body):
	var response_text = body.get_string_from_utf8()
	var json = JSON.parse_string(response_text)
	
	if json == null:
		show_message("Error", "Server is unreachable.")
		return
	
	if response_code == 200:
		auth_token = json.get("token", "")
		var record = json.get("record", {})
		user_id = record.get("id", "")
		username = record.get("username", "Player")
		is_logged_in = true
		is_vtrolly_connected = record.get("is_vtrolly_connected", false)
		vcoins = int(record.get("vcoins", 0))

		save_session()
		get_tree().change_scene_to_file("res://Client/Scenes/MainMenu.tscn")
	else:
		var msg = json.get("message", "Incorrect email or password.")
		show_message("Log in error", msg)

func register_user(email, password):
	var body = JSON.stringify({
		"email": email,
		"emailVisibility": true,
		"password": password,
		"passwordConfirm": password, # PocketBase requires this to match
		"name": email.split("@")[0],  # Optional: Default name from email
		"vcoins": 0
	})
	
	var headers = ["Content-Type: application/json"]
	
	# Connect the signal ONLY if it isn't already connected
	if not http_request.request_completed.is_connected(_on_register_completed):
		http_request.request_completed.connect(_on_register_completed)
		
	http_request.request(BACKEND_URL + "/api/collections/users/records", headers, HTTPClient.METHOD_POST, body)

func _on_register_completed(result, response_code, headers, body):
	# Disconnect so it doesn't interfere with login signals
	if http_request.request_completed.is_connected(_on_register_completed):
		http_request.request_completed.disconnect(_on_register_completed)
		
	var response_text = body.get_string_from_utf8()
	var json = JSON.parse_string(response_text)
	
	if response_code == 200 or response_code == 204:
		show_message("Registration Complete", "Registration Successful! Please log in.")
	elif response_code == 400:
		if "identity" in json.get("data", {}):
			show_message("Registration Error", "This email is already taken.")
		else:
			show_message("Registration Error", "Registration failed. Please check your details.")

func sync_with_mongodb(pb_id):
	var node_http = HTTPRequest.new()
	add_child(node_http)
	
	var body = JSON.stringify({"pb_user_id": pb_id})
	var headers = ["Content-Type: application/json"]
	
	node_http.request("http://localhost:3000/sync-player", headers, HTTPClient.METHOD_POST, body)

func show_message(MainText: String, MessageText: String):
	var popup = popup_scene.instantiate()
	get_tree().root.add_child(popup)
	popup.set_message(MainText, MessageText)
	
# Validation logic
func is_valid_email(email: String) -> bool:
	var regex = RegEx.new()
	regex.compile("^[\\w\\-\\.]+@([\\w-]+\\.)+[\\w-]{2,4}$")
	return regex.search(email) != null

func is_strong_password(password: String) -> String:
	if password.length() < 6: return "Password must be at least 6 characters."
	if not RegEx.create_from_string("[A-Z]").search(password): return "Need one uppercase letter."
	if not RegEx.create_from_string("[a-z]").search(password): return "Need one lowercase letter."
	if not RegEx.create_from_string("[0-9]").search(password): return "Need one number."
	if not RegEx.create_from_string("[^A-Za-z0-9]").search(password): return "Need one special character."
	return "" # Empty string means it passed

func connect_vtrolly_account(vtrolly_email, vtrolly_password):
	var node_http = HTTPRequest.new()
	add_child(node_http)
	
	var body = JSON.stringify({
		"email": vtrolly_email.strip_edges(), # Remove accidental spaces
		"password": vtrolly_password,
		"pb_user_id": user_id,
		"pb_token": auth_token
	})
	
	var headers = ["Content-Type: application/json"]
	
	node_http.request("http://localhost:3000/api/player/connect", headers, HTTPClient.METHOD_POST, body)
	
	# Connect using a lambda function
	node_http.request_completed.connect(func(result, response_code, headers, body_raw):
		var response_text = body_raw.get_string_from_utf8()
		
		var json = JSON.parse_string(response_text)
		
		if json == null:
			show_message("Connection Error", "Server error. Please check backend logs.")
			node_http.queue_free()
			return
		
		if response_code == 200:
			# Update the local boolean immediately so the UI reflects it
			is_vtrolly_connected = true 
			
			# Update PocketBase
			update_pocketbase_with_link(json["vtrolly_id"])
			
			# REFRESH local vcoins before leaving
			refresh_user_data() 
			
			show_message("Connection Complete", "Vtrolly Account Connected!")
			# Return to Main Menu
			get_tree().change_scene_to_file("res://Client/Scenes/MainMenu.tscn")
		else:
			var error_msg = "Connection failed"
			if json and json.has("message"):
				error_msg = json["message"]
			show_message("Connection Error", "Error: " + error_msg)
		
		node_http.queue_free()
	)

func update_pocketbase_with_link(vtrolly_id):
	var url = BACKEND_URL + "/api/collections/users/records/" + user_id
	var body = JSON.stringify({
		"is_vtrolly_connected": true,
		"mongo_id": vtrolly_id
	})
	var headers = [
		"Content-Type: application/json",
		"Authorization: " + auth_token # PocketBase needs the user's token to allow updates
	]
	http_request.request(url, headers, HTTPClient.METHOD_PATCH, body)

func refresh_user_data():
	if not is_logged_in: return
	
	var node_http = HTTPRequest.new()
	add_child(node_http)
	
	var url = BACKEND_URL + "/api/collections/users/records/" + user_id
	var headers = ["Authorization: " + auth_token]
	
	node_http.request(url, headers, HTTPClient.METHOD_GET)
	node_http.request_completed.connect(func(result, response_code, headers, body_raw):
		if response_code == 200:
			var json = JSON.parse_string(body_raw.get_string_from_utf8())
			vcoins = int(json.get("vcoins", 0))
			is_vtrolly_connected = json.get("is_vtrolly_connected", false)
			
			# Emit a signal so the UI knows to update
			emit_signal("user_data_updated")
		node_http.queue_free()
	)

func save_session():
	var config = ConfigFile.new()
	config.set_value("auth", "token", auth_token)
	config.set_value("auth", "user_id", user_id)
	config.set_value("auth", "timestamp", Time.get_unix_time_from_system())
	var err = config.save(SAVE_PATH)
	
func load_session():
	var config = ConfigFile.new()
	var err = config.load(SAVE_PATH)
	if err != OK: return # No session saved
	
	var saved_time = config.get_value("auth", "timestamp", 0.0)
	var current_time = Time.get_unix_time_from_system()
	
	# Check if 14 days have passed
	if current_time - saved_time > SESSION_EXPIRY_SECONDS:
		logout_user()
		return
	
	var saved_token = config.get_value("auth", "token", "")
	var saved_id = config.get_value("auth", "user_id", "")
	
	if saved_token != "":
		# Try to validate the token by fetching user data
		auth_token = saved_token
		user_id = saved_id
		is_logged_in = true
		refresh_user_data() # This will populate username and vcoins

func logout_user():
	auth_token = ""
	user_id = ""
	username = ""
	vcoins = 0
	is_logged_in = false
	is_vtrolly_connected = false
	
	# Delete the "cookie" file
	var dir = DirAccess.open("user://")
	if dir.file_exists("session.cfg"):
		dir.remove("session.cfg")
	
	get_tree().change_scene_to_file("res://Client/Scenes/LogInRegister.tscn")
