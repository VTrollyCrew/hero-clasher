extends Node

var popup_scene = preload("res://Client/Scenes/UI/PopupMessage.tscn")

# The address where your backend (PocketBase) is running
const BACKEND_URL = "http://127.0.0.1:8090"
var http_request : HTTPRequest

# Store the token after logging in
var is_logged_in : bool = false
var username : String = ""
var auth_token = ""
var user_id = ""

func _ready():
	http_request = HTTPRequest.new()
	add_child(http_request)

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
	
	print("Raw Body: ", response_text)
	
	if response_code == 200:
		# --- UPDATE THESE LINES ---
		auth_token = json["token"]
		user_id = json["record"]["id"]
		username = json["record"].get("username", "Player") # Gets username from PocketBase
		is_logged_in = true
			
		print("✅ Success! Welcome ", username)
		get_tree().change_scene_to_file("res://Client/Scenes/MainMenu.tscn")
	else:
		show_message("Incorrect email or password.")

func register_user(email, password):
	print("AuthManager: Attempting to register ", email)
	
	var body = JSON.stringify({
		"email": email,
		"emailVisibility": true,
		"password": password,
		"passwordConfirm": password, # PocketBase requires this to match
		"name": email.split("@")[0]  # Optional: Default name from email
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
		show_message("Registration Successful! Please log in.")
	elif response_code == 400:
		if "identity" in json.get("data", {}):
			show_message("This email is already taken.")
		else:
			show_message("Registration failed. Please check your details.")

func sync_with_mongodb(pb_id):
	var node_http = HTTPRequest.new()
	add_child(node_http)
	
	var body = JSON.stringify({"pb_user_id": pb_id})
	var headers = ["Content-Type: application/json"]
	
	node_http.request("http://localhost:3000/sync-player", headers, HTTPClient.METHOD_POST, body)
	node_http.request_completed.connect(func(result, response_code, headers, body):
		print("MongoDB Sync Response: ", body.get_string_from_utf8())
	)
	
func update_pocketbase_with_link(vtrolly_id):
	var url = BACKEND_URL + "/api/collections/users/records/" + user_id
	var body = JSON.stringify({
		"vtrolly_linked": true,
		"mongo_id": vtrolly_id
	})
	var headers = [
		"Content-Type: application/json",
		"Authorization: " + auth_token # PocketBase needs the user's token to allow updates
	]
	http_request.request(url, headers, HTTPClient.METHOD_PATCH, body)

func show_message(text: String):
	var popup = popup_scene.instantiate()
	get_tree().root.add_child(popup)
	popup.set_message(text)
	
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
