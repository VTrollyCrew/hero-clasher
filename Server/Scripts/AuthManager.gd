extends Node

# The address where your backend (PocketBase) is running
const BACKEND_URL = "http://127.0.0.1:8090"
var http_request : HTTPRequest

# Store the token after logging in
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
	print("--- Backend Response Received ---")
	print("HTTP Code: ", response_code)
	
	var response_text = body.get_string_from_utf8()
	print("Raw Body: ", response_text)

	var json = JSON.parse_string(response_text)
	if response_code == 200:
		print("✅ Success! Token: ", json["token"].left(10), "...")
		auth_token = json["token"]
		user_id = json["record"]["id"]
	else:
		print("❌ Failed. Message: ", json.get("message", "No message provided"))

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
		print("✅ Registration Successful! You can now login.")
	else:
		print("❌ Registration Failed: ", json)
