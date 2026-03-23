extends Node

signal decks_loaded(decks: Array)
signal deck_created(deck: Dictionary)
signal deck_deleted(deck_id: String)
signal error_occurred(message: String)

var http_request: HTTPRequest

var request_counter = 0
var pending_requests = {}         # request_id -> action
var current_editing_deck_id: String = "" # used to pass ID to deck builder

const BASE_URL = "http://127.0.0.1:8090"
const ROOMS_COLLECTION = "decks"

func _ready() -> void:
	http_request = HTTPRequest.new()
	add_child(http_request)
	if not http_request.request_completed.is_connected(_on_request_completed):
		http_request.request_completed.connect(_on_request_completed)
	
func list_decks():
	print("📤 DeckManager.list_decks() called")
	if not AuthManager.is_logged_in:
		emit_signal("error_occurred", "Not logged in")
		return
	
	var url = AuthManager.BACKEND_URL + "/api/collections/decks/records?filter=(user='%s')&sort=-created" % AuthManager.user_id
	var headers = ["Authorization: " + AuthManager.auth_token]
	
	request_counter += 1
	var request_id = request_counter
	pending_requests[request_id] = "list"
	
	# Store the request_id in the HTTPRequest node's metadata
	http_request.set_meta("request_id", request_id)
	print("📌 Set request_id metadata to: ", request_id, " for list")   # ← new
	
	print("➡️ Sending list request to: ", url) 
	http_request.request(url, headers, HTTPClient.METHOD_GET)
	
func create_deck(name: String = "New Deck"):
	if not AuthManager.is_logged_in:
		emit_signal("error_occurred", "Not logged in")
		return
		
	var url = AuthManager.BACKEND_URL + "/api/collections/decks/records"
	var body = JSON.stringify({
		"user": AuthManager.user_id,
		"deck_name": name,
		"card_count": 0
	})
	var headers = ["Content-Type: application/json", "Authorization: " + AuthManager.auth_token]
	
	request_counter += 1
	var request_id = request_counter
	pending_requests[request_id] = "create"
	
	# For create, also set metadata (you missed this before)
	http_request.set_meta("request_id", request_id)
	print("📌 Set request_id metadata to: ", request_id, " for create")   # ← new
	
	http_request.request(url, headers, HTTPClient.METHOD_POST, body)
	
func delete_deck(deck_id: String):
	if not AuthManager.is_logged_in:
		emit_signal("error_occurred", "Not logged in")
		return
		
	var url = AuthManager.BACKEND_URL + "/api/collections/decks/records/" + deck_id
	var headers = ["Authorization: " + AuthManager.auth_token]
	
	request_counter += 1
	var request_id = request_counter
	pending_requests[request_id] = "delete"

	set_meta("pending_deck_id", deck_id)
	# For delete, also set metadata
	http_request.set_meta("request_id", request_id)
	print("📌 Set request_id metadata to: ", request_id, " for delete")   # ← new
	
	http_request.request(url, headers, HTTPClient.METHOD_DELETE)

func _on_request_completed(result, response_code, headers, body):
	var request_id = http_request.get_meta("request_id", 0)
	var action = pending_requests.get(request_id, "")
	
	print("🌐 Request completed: id=", request_id, " action=", action, " code=", response_code)
	print("   Pending keys: ", pending_requests.keys())   # ← new
	print("   Retrieved request_id from meta: ", request_id)   # ← new
	
	if action == "":
		print("⚠️ No pending action for this request_id – ignoring.")
		return
	
	# Remove the request from pending
	pending_requests.erase(request_id)
	
	var response_text = body.get_string_from_utf8()
	var json = JSON.parse_string(response_text)
	
	if response_code != 200 and response_code != 204:
		emit_signal("error_occurred", "Request failed: %d - %s" % [response_code, response_text])
		return
		
	match action:
		"list":
			print("📩 List response received, code: ", response_code)
			if json and json.has("items"):
				emit_signal("decks_loaded", json["items"])
			else:
				print("⚠️ No items in response, json: ", json)
				emit_signal("decks_loaded", [])
		"create":
			print("📦 Create response received")
			if json and json.has("id"):
				emit_signal("deck_created", json)
			else:
				emit_signal("error_occurred", "Failed to create deck")
		"delete":
			var deck_id = get_meta("pending_deck_id", "")
			print("✅ Delete completed for deck: ", deck_id)
			emit_signal("deck_deleted", deck_id)
		_:
			print("Unknown action: ", action)
