extends Node

signal rooms_updated(rooms)          # Emitted when public room list changes
signal room_updated(room_data)       # Emitted when the current room's data changes
signal player_joined(player_data)    # (Optional) emitted when a player joins
signal player_left(player_id)        # (Optional) emitted when a player leaves
signal game_started()                 # Emitted when host starts the game

const BASE_URL = "http://127.0.0.1:8090"
const ROOMS_COLLECTION = "rooms"

var popup_scene = preload("res://Client/Scenes/UI/PopupMessage.tscn")

var current_room_id: String = ""
var current_room_data: Dictionary = {}
var http_request: HTTPRequest
var realtime_subscription: WebSocketPeer  # For PocketBase realtime

func _room_url(record_id: String = "") -> String:
	var url = BASE_URL + "/api/collections/" + ROOMS_COLLECTION + "/records"
	if record_id != "":
		url += "/" + record_id
	url += "?expand=host_id,player_1_id,player_2_id,spectator_ids"
	return url

func _ready():
	http_request = HTTPRequest.new()
	add_child(http_request)
	# Connect signals if needed

# ---------- Room Creation ----------
func create_room(room_name: String, max_players: int, allow_spectators: bool, visibility: String, password: String = "") -> void:
	print("=== create_room called ===")
	print("room_name: ", room_name)
	print("max_players: ", max_players)
	print("allow_spectators: ", allow_spectators)
	print("visibility: ", visibility)
	print("password: ", password)
	print("AuthManager.user_id: ", AuthManager.user_id)
	print("AuthManager.auth_token: ", AuthManager.auth_token)
	
	# Create a new room. The host is the current user.
	var body = {
		"room_name": room_name,
		"host_id": AuthManager.user_id,
		"all_players": [AuthManager.user_id],
		"player_1_id": AuthManager.user_id,   # Host takes player slot 1
		"player_2_id": null,
		"max_players": max_players,
		"allow_spectators": allow_spectators,
		"spectator_ids": [],
		"state": "open",
		"visibility": visibility,
		"password": password if visibility == "private" else "",
		"player_1_ready": false,
		"player_2_ready": false,
	}
	var headers = [
		"Content-Type: application/json",
		"Authorization: " + AuthManager.auth_token
	]
	var url = _room_url()
	print("POST URL: ", url)
	print("Request body: ", JSON.stringify(body))
	print("Headers: ", headers)
	
	# Ensure any previous connection is cleared
	if http_request.request_completed.is_connected(_on_room_created):
		http_request.request_completed.disconnect(_on_room_created)
	http_request.request_completed.connect(_on_room_created, CONNECT_ONE_SHOT)
	
	var err = http_request.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		print("HTTPRequest error: ", err)

func _on_room_created(result, response_code, headers, body):
	var json = JSON.parse_string(body.get_string_from_utf8())
	if response_code == 200:
		current_room_id = json["id"]
		current_room_data = json
		# Automatically join this room's realtime subscription
		subscribe_to_room(current_room_id)
		emit_signal("room_updated", current_room_data)
		# Switch to waiting room scene
		get_tree().change_scene_to_file("res://Client/Scenes/WaitingRoom.tscn")
	else:
		var msg = json.get("message", "Unknown error") if json else "Unknown error"
		show_message("Create Failed", msg)

# ---------- Fetch Public Rooms ----------
func fetch_public_rooms() -> void:
	"""
	Fetch all rooms with visibility = 'public' and state = 'open'.
	"""
	print("Fetching public rooms with token: ", AuthManager.auth_token)  # Debug
	var filter = "visibility='public' && state='open'"
	var encoded_filter = filter.uri_encode()
	var url = BASE_URL + "/api/collections/" + ROOMS_COLLECTION + "/records?filter=" + encoded_filter
	print("URL: ", url)
	var headers = ["Authorization: " + AuthManager.auth_token]
	
	http_request.request_completed.connect(_on_rooms_fetched, CONNECT_ONE_SHOT)
	http_request.request(url, headers, HTTPClient.METHOD_GET)

func _on_rooms_fetched(result, response_code, headers, body):
	var response_text = body.get_string_from_utf8()
	print("Fetch rooms response code: ", response_code)
	print("Response body: ", response_text)
	if response_code == 200:
		var json = JSON.parse_string(response_text)
		if json and json.has("items"):
			emit_signal("rooms_updated", json["items"])
		else:
			print("Invalid response format")
	else:
		print("Failed to fetch rooms: ", response_text)

# ---------- Join Room ----------
func join_room(room_id: String, password: String = "") -> void:
	# Attempt to join a room. If private, password must match.

	# First fetch room details to check password and capacity
	var url = _room_url(room_id)
	var headers = ["Authorization: " + AuthManager.auth_token]
	
	http_request.request_completed.connect(_on_room_fetched_for_join.bind(password), CONNECT_ONE_SHOT)
	http_request.request(url, headers, HTTPClient.METHOD_GET)

func _on_room_fetched_for_join(result, response_code, headers, body, password: String):
	if response_code != 200:
		print("Room not found")
		show_message("Join Failed", "Room not found")
		return
	
	var room = JSON.parse_string(body.get_string_from_utf8())
	# Check password if private
	if room["visibility"] == "private" and room["password"] != password:
		print("Incorrect password")
		show_message("Join Failed", "Incorrect Password")
		return
	
	# Check if room is full (all_players length >= max_players, but note we have separate player slots)
	var current_players = room["all_players"] if room["all_players"] else []
	if current_players.size() >= room["max_players"]:
		print("Room is full")
		show_message("Join Failed", "Room is Full")
		return
	
	# Add current user to all_players and assign to a free slot (player_1 or player_2)
	var update_data = {}
	var all_players = current_players.duplicate()
	all_players.append(AuthManager.user_id)
	update_data["all_players"] = all_players
	
	# Assign to player slot if available
	if room["player_1_id"] == null or room["player_1_id"] == "":
		update_data["player_1_id"] = AuthManager.user_id
		update_data["player_1_ready"] = false
	elif room["player_2_id"] == null or room["player_2_id"] == "":
		update_data["player_2_id"] = AuthManager.user_id
		update_data["player_2_ready"] = false
	else:
		# No free player slot, but room still has capacity? Possibly they become spectator.
		# For now, just add to all_players and they will be spectator.
		pass
	
	# Perform PATCH to update room
	var patch_url = _room_url(room["id"])
	var patch_headers = [
		"Content-Type: application/json",
		"Authorization: " + AuthManager.auth_token
	]
	http_request.request_completed.connect(_on_room_joined, CONNECT_ONE_SHOT)
	http_request.request(patch_url, patch_headers, HTTPClient.METHOD_PATCH, JSON.stringify(update_data))

func _on_room_joined(result, response_code, headers, body):
	if response_code == 200:
		var room = JSON.parse_string(body.get_string_from_utf8())
		current_room_id = room["id"]
		current_room_data = room
		subscribe_to_room(current_room_id)
		emit_signal("room_updated", current_room_data)
		get_tree().change_scene_to_file("res://Client/Scenes/WaitingRoom.tscn")
	else:
		print("Failed to join room")
		show_message("Join Failed", "Could not join to room")

# ---------- Leave Room ----------
func leave_room() -> void:
	"""
	Remove current user from the room. If host leaves, either delete room or assign new host.
	"""
	if current_room_id == "":
		return
		
	# If current user is the host, delete the room
	if current_room_data.get("host_id") == AuthManager.user_id:
		delete_room(current_room_id)
		return
	
	# Fetch latest room data
	var url = _room_url(current_room_id)
	var headers = ["Authorization: " + AuthManager.auth_token]
	
	http_request.request_completed.connect(_on_room_fetched_for_leave, CONNECT_ONE_SHOT)
	http_request.request(url, headers, HTTPClient.METHOD_GET)

func _on_room_fetched_for_leave(result, response_code, headers, body):
	if response_code != 200:
		exit_room()
		return
	
	var room = JSON.parse_string(body.get_string_from_utf8())
	var all_players = room["all_players"] if room["all_players"] else []
	
	# Remove current user from all_players and from specific slots
	all_players.erase(AuthManager.user_id)
	var update_data = {
		"all_players": all_players
	}
	if room["player_1_id"] == AuthManager.user_id:
		update_data["player_1_id"] = null
	if room["player_2_id"] == AuthManager.user_id:
		update_data["player_2_id"] = null
	# Also remove from spectator_ids if present
	if room.has("spectator_ids") and room["spectator_ids"]:
		var spectators = room["spectator_ids"].duplicate()
		spectators.erase(AuthManager.user_id)
		update_data["spectator_ids"] = spectators
	
	# Perform PATCH
	var patch_url = _room_url(current_room_id)
	var patch_headers = [
		"Content-Type: application/json",
		"Authorization: " + AuthManager.auth_token
	]
	http_request.request_completed.connect(_on_room_left, CONNECT_ONE_SHOT)
	http_request.request(patch_url, patch_headers, HTTPClient.METHOD_PATCH, JSON.stringify(update_data))

func _on_room_left(result, response_code, headers, body):
	# Unsubscribe from realtime
	if response_code == 200:
		print("Successfully left room")
		show_message("Left Room", "You have left the room.")
	else:
		print("Failed to leave room, but exiting anyway")
		show_message("Error", "Failed to leave room properly.")
		
	await get_tree().create_timer(1.5).timeout
	exit_room()

func delete_room(room_id: String):
	var url = BASE_URL + "/api/collections/" + ROOMS_COLLECTION + "/records/" + room_id
	var headers = ["Authorization: " + AuthManager.auth_token]
	http_request.request_completed.connect(_on_room_deleted, CONNECT_ONE_SHOT)
	http_request.request(url, headers, HTTPClient.METHOD_DELETE)

func _on_room_deleted(result, response_code, headers, body):
	if response_code == 204:
		print("Room deleted")
		show_message("Room Closed", "The host has left. The room is now closed.")
	else:
		print("Failed to delete room, but exiting anyway")
		show_message("Error", "Could not delete room.")
		
	await get_tree().create_timer(1.5).timeout
	exit_room()

# ---------- Realtime Subscriptions ----------
func subscribe_to_room(room_id: String):
	"""
	Open a WebSocket connection to PocketBase to listen for changes on this room.
	PocketBase realtime endpoint: ws://127.0.0.1:8090/api/realtime
	We subscribe to the specific record.
	"""
	# You need to implement WebSocket handling. PocketBase expects a client ID and subscription messages.
	# For simplicity, you might use HTTP polling, but realtime is better.
	# I'll outline the approach:
	# 1. Create WebSocketPeer and connect to ws://127.0.0.1:8090/api/realtime
	# 2. Send a message like: {"clientId": "some-unique-id"} (or omit)
	# 3. Then send subscription: {"action": "subscribe", "subscriptions": ["rooms/"+room_id]}
	# 4. Handle incoming messages and emit room_updated.
	#
	# Here's a basic implementation using HTTP polling as fallback if WebSocket is complex.
	# Poll every 2 seconds for changes.
	if realtime_subscription:
		# Already subscribed, maybe close previous
		pass
	
	# For simplicity, we'll set up a timer to poll the room data periodically.
	var timer = Timer.new()
	timer.name = "RoomPollTimer"
	timer.wait_time = 2.0
	timer.autostart = true
	timer.timeout.connect(_poll_room_data)
	add_child(timer)

func _poll_room_data():
	if current_room_id == "":
		return
	var url = _room_url(current_room_id)
	var headers = ["Authorization: " + AuthManager.auth_token]
	http_request.request_completed.connect(_on_room_polled, CONNECT_ONE_SHOT)
	http_request.request(url, headers, HTTPClient.METHOD_GET)

func _on_room_polled(result, response_code, headers, body):
	if response_code == 200:
		var room = JSON.parse_string(body.get_string_from_utf8())
		current_room_data = room
		emit_signal("room_updated", room)
	else:
		# Room might be deleted
		if response_code == 404:
			current_room_id = ""
			get_tree().change_scene_to_file("res://Client/Scenes/Lobby.tscn")

# ---------- Host Actions ----------
func kick_player(player_id: String):
	"""
	Host kicks a player from the room.
	"""
	if current_room_data["host_id"] != AuthManager.user_id:
		print("Only host can kick")
		show_message("Kick Failed", "Only host can kick players out from room")
		return
	if player_id == AuthManager.user_id:
		print("Host cannot kick themselves")
		show_message("Kick Failed", "Host cannot kick themselves out from room")
		return
	
	var all_players = current_room_data["all_players"].duplicate()
	all_players.erase(player_id)
	var update_data = {
		"all_players": all_players
	}
	if current_room_data["player_1_id"] == player_id:
		update_data["player_1_id"] = null
	if current_room_data["player_2_id"] == player_id:
		update_data["player_2_id"] = null
	if current_room_data.has("spectator_ids"):
		var spectators = current_room_data["spectator_ids"].duplicate()
		spectators.erase(player_id)
		update_data["spectator_ids"] = spectators
	
	var url = _room_url(current_room_id)
	var headers = [
		"Content-Type: application/json",
		"Authorization: " + AuthManager.auth_token
	]
	http_request.request_completed.connect(_on_kick_completed, CONNECT_ONE_SHOT)
	http_request.request(url, headers, HTTPClient.METHOD_PATCH, JSON.stringify(update_data))

func _on_kick_completed(result, response_code, headers, body):
	if response_code == 200:
		print("Player kicked")
	else:
		print("Failed to kick")

func assign_slot(player_id: String, slot: String):
	"""
	slot: "player_1_id" or "player_2_id" or "spectator"
	"""
	if current_room_data["host_id"] != AuthManager.user_id:
		print("Only host can assign slots")
		return
	
	var update_data = {}
	
	# Remove from any existing slot
	if current_room_data["player_1_id"] == player_id:
		update_data["player_1_id"] = null
	if current_room_data["player_2_id"] == player_id:
		update_data["player_2_id"] = null
	if current_room_data.has("spectator_ids") and current_room_data["spectator_ids"].has(player_id):
		var spectators = current_room_data["spectator_ids"].duplicate()
		spectators.erase(player_id)
		update_data["spectator_ids"] = spectators
	
	# Assign to new slot
	if slot == "player_1_id":
		update_data["player_1_id"] = player_id
	elif slot == "player_2_id":
		update_data["player_2_id"] = player_id
	elif slot == "spectator":
		var spectators = current_room_data.get("spectator_ids", [])
		if player_id not in spectators:
			spectators.append(player_id)
			update_data["spectator_ids"] = spectators
	
	# Ensure player is in all_players
	var all_players = current_room_data["all_players"].duplicate()
	if player_id not in all_players:
		all_players.append(player_id)
		update_data["all_players"] = all_players
	
	var url = _room_url(current_room_id)
	var headers = [
		"Content-Type: application/json",
		"Authorization: " + AuthManager.auth_token
	]
	http_request.request_completed.connect(_on_assign_completed, CONNECT_ONE_SHOT)
	http_request.request(url, headers, HTTPClient.METHOD_PATCH, JSON.stringify(update_data))

func _on_assign_completed(result, response_code, headers, body):
	if response_code == 200:
		print("Slot assigned")
	else:
		print("Failed to assign slot")

# ---------- Start Game ----------
func start_game():
	"""
	Host starts the game. This will:
	- Set room state to 'closed' (optional)
	- Notify all players via realtime (so they can prepare)
	- Actually, after starting, we need to establish ENet connection.
	We'll use the existing Multiplayer.gd to host/join.
	"""
	if current_room_data["host_id"] != AuthManager.user_id:
		print("Only host can start game")
		return
		
	var p1_id = current_room_data.get("player_1_id")
	var p2_id = current_room_data.get("player_2_id")
	var p1_ready = current_room_data.get("player_1_ready", false)
	var p2_ready = current_room_data.get("player_2_ready", false)
	
	if not p1_id or not p2_id:
		show_message("Cannot Start", "Both player slots must be filled.")
		return
	
	if not p1_ready or not p2_ready:
		show_message("Cannot Start", "Both players must be ready.")
		return
	
	# Optionally update room state to 'closed'
	var url = _room_url(current_room_id)
	var headers = [
		"Content-Type: application/json",
		"Authorization: " + AuthManager.auth_token
	]
	var update_data = {"state": "closed"}
	http_request.request_completed.connect(_on_room_closed_for_game, CONNECT_ONE_SHOT)
	http_request.request(url, headers, HTTPClient.METHOD_PATCH, JSON.stringify(update_data))

func _on_room_closed_for_game(result, response_code, headers, body):
	if response_code == 200:
		# Now the host should start the ENet server
		# We'll use the existing Multiplayer autoload or instance
		# Assuming Multiplayer.gd is an autoload named "Multiplayer"
		Multiplayer.host_game()  # This should create server and maybe load game scene
		# Also notify clients to join the host via ENet
		emit_signal("game_started")
	else:
		print("Failed to close room")

func exit_room():
	# Clean up realtime subscription (if using WebSocket)
	if realtime_subscription:
		# Close WebSocket connection
		realtime_subscription.close()
		realtime_subscription = null
	
	# Remove poll timer if exists
	var timer = get_node_or_null("RoomPollTimer")
	if timer:
		timer.stop()
		timer.queue_free()
	
	current_room_id = ""
	current_room_data = {}
	get_tree().change_scene_to_file("res://Client/Scenes/Lobby.tscn")

func show_message(MainText: String, MessageText: String):
	var popup = popup_scene.instantiate()
	get_tree().root.add_child(popup)
	popup.set_message(MainText, MessageText)

func set_ready(ready: bool):
	if current_room_id == "":
		return
	
	var update_data = {}
	if current_room_data.get("player_1_id") == AuthManager.user_id:
		update_data["player_1_ready"] = ready
	elif current_room_data.get("player_2_id") == AuthManager.user_id:
		update_data["player_2_ready"] = ready
	else:
		# Spectator – cannot ready up
		show_message("Ready", "Spectators cannot ready up.")
		return
	
	var url = _room_url(current_room_id)
	var headers = [
		"Content-Type: application/json",
		"Authorization: " + AuthManager.auth_token
	]
	http_request.request_completed.connect(_on_ready_updated, CONNECT_ONE_SHOT)
	http_request.request(url, headers, HTTPClient.METHOD_PATCH, JSON.stringify(update_data))

func _on_ready_updated(result, response_code, headers, body):
	if response_code == 200:
		print("Ready status updated")
		# Room data will be updated via polling, no further action needed
	else:
		show_message("Error", "Failed to update ready status.")
