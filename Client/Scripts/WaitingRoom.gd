# This is the waiting room script
# All waiting room functions from client side are handled here
# Any players who joined in to the room are displayed here
# All data are then passed to the RoomManager server side script
# This is directly attached to the WaitingRoom.tscn scene

# Codebase is referencing on multiple sources
# Source 1: https://docs.godotengine.org (For scene GUI container, scene tree management, button management, etc). This is the official documentation
# Source 2: Deepseek AI (For reference code)

extends Control

@onready var room_name_label = $VBoxContainer/RoomNameLabel
@onready var host_label = $VBoxContainer/HostLabel
@onready var player_list =  $VBoxContainer/ScrollContainer/PlayerList 
@onready var ready_button = $VBoxContainer/ReadyToggleButton
@onready var start_button = $VBoxContainer/HBoxContainer/StartButton
@onready var leave_button = $VBoxContainer/HBoxContainer/LeaveButton

var is_host: bool = false

func _ready():
	RoomManager.room_updated.connect(_on_room_updated)
	RoomManager.game_started.connect(_on_game_started)
	
	if not ready_button.pressed.is_connected(_on_ready_toggle_button_pressed):
		ready_button.pressed.connect(_on_ready_toggle_button_pressed)
	
	# Initial update with current data
	_update_ui(RoomManager.current_room_data)

func _on_room_updated(room_data):
	_update_ui(room_data)

func _update_ui(room_data):
	if room_data.is_empty():
		return
		
	# Check if current user is still in the room
	var all_players = room_data.get("all_players", [])
	if AuthManager.user_id not in all_players:
		# User was kicked or room deleted
		RoomManager.show_message("Kicked", "You have been kicked from the room.")
		await get_tree().create_timer(1.5).timeout
		RoomManager.exit_room()
		return
	
	room_name_label.text = room_data["room_name"]
	
	var host_name = room_data["host_id"]  # fallback to ID
	if room_data.has("expand") and room_data["expand"].has("host_id"):
		var host_record = room_data["expand"]["host_id"]
		if host_record.has("username"):
			host_name = host_record["username"]
	host_label.text = "Host: " + host_name
	
	is_host = (room_data["host_id"] == AuthManager.user_id)
	start_button.visible = is_host
	
	# Determine my ready status
	var my_ready_status = false
	if room_data.get("player_1_id") == AuthManager.user_id:
		my_ready_status = room_data.get("player_1_ready", false)
	elif room_data.get("player_2_id") == AuthManager.user_id:
		my_ready_status = room_data.get("player_2_ready", false)
		
	# Update ready button
	if room_data.get("player_1_id") == AuthManager.user_id or room_data.get("player_2_id") == AuthManager.user_id:
		ready_button.visible = true
		ready_button.text = "Not Ready" if my_ready_status else "Ready"
	else:
		ready_button.visible = false # Spectators
	
	# Clear player list
	for child in player_list.get_children():
		child.queue_free()  # Implement a helper to clear nodes
	
	# Player slots
	# Player 1
	if room_data.get("player_1_id"):
		var player_data = room_data["player_1_id"]
		if room_data.has("expand") and room_data["expand"].has("player_1_id"):
			player_data = room_data["expand"]["player_1_id"]
		_add_player_entry(player_data, "Player 1", room_data, "player_1")
	else:
		_add_empty_slot("Player 1")
		
	# Player 2
	if room_data.get("player_2_id"):
		var player_data = room_data["player_2_id"]
		if room_data.has("expand") and room_data["expand"].has("player_2_id"):
			player_data = room_data["expand"]["player_2_id"]
		_add_player_entry(player_data, "Player 2", room_data, "player_2")
	else:
		_add_empty_slot("Player 2")
		

	# Spectators (if allowed)
	if room_data.get("allow_spectators", false):
		var spectator_ids = room_data.get("spectator_ids", [])
		var spectator_expand = room_data.get("expand", {}).get("spectator_ids", [])
		for i in range(spectator_ids.size()):
			var player_data = spectator_ids[i]
			if i < spectator_expand.size():
				player_data = spectator_expand[i]
			_add_player_entry(player_data, "Spectator", room_data, "spectator")
			

func _add_player_entry(player_data, role, room_data, slot):
	var entry = preload("res://Client/Scenes/PlayerEntry.tscn").instantiate()
	player_list.add_child(entry)
	
	# Extract player ID for kick callback
	var player_id = player_data if typeof(player_data) == TYPE_STRING else player_data.get("id")
	
	# Determine if this player is the host
	var is_this_player_host = (player_id == room_data["host_id"])
	
	# Show kick button only if current user is host AND this player is NOT the host
	var show_kick = is_host and not is_this_player_host
	
	# Get ready status based on slot
	var ready = false
	if slot == "player_1":
		ready = room_data.get("player_1_ready", false)
	elif slot == "player_2":
		ready = room_data.get("player_2_ready", false)
	# Spectators have no ready status
	
	entry.setup(player_data, role, show_kick, ready)
	entry.set_meta("player_id", player_id)
	
	# Connect kick signal if host
	if show_kick:
		entry.kick_requested.connect(_on_kick_requested.bind(entry))

func _add_empty_slot(role):
	var entry = preload("res://Client/Scenes/PlayerEntry.tscn").instantiate()
	player_list.add_child(entry)
	entry.set_empty(role)
	
func _on_ready_toggle_button_pressed():
	# Determine current ready status
	var current_ready = false
	if RoomManager.current_room_data.get("player_1_id") == AuthManager.user_id:
		current_ready = RoomManager.current_room_data.get("player_1_ready", false)
	elif RoomManager.current_room_data.get("player_2_id") == AuthManager.user_id:
		current_ready = RoomManager.current_room_data.get("player_2_ready", false)
	else:
		return
		
	RoomManager.set_ready(not current_ready)

func _on_kick_requested(entry):
	var player_id = entry.get_meta("player_id")
	RoomManager.kick_player(player_id)

func _on_game_started():
	# Currently this is operating in localhost due to the available resources
	if not is_host:
		Multiplayer.join_game("localhost") 


func _on_start_button_pressed() -> void:
	RoomManager.start_game()


func _on_leave_button_pressed() -> void:
	RoomManager.leave_room()
