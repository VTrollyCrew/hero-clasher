# This is the Lobby script
# The lobby is the first stage where users are accessing the game with
# The lobby holds what rooms are active, which are open and how many users are allowed to join in
# Additionally, users can create rooms in the lobby menu
# The create room modal carries all of the options needed to the room lobby 

# Reference is included in the AuthManager.gd script since that is the main code is located

extends Control

@onready var rooms_container = $VBoxContainer/ScrollContainer/RoomContainer
@onready var create_room_dialog = $CreateRoomDialog
@onready var room_name_edit = create_room_dialog.get_node("PanelContainer/VBoxContainer/RoomNameEditText")
@onready var max_players_spin = create_room_dialog.get_node("PanelContainer/VBoxContainer/MaxPlayersSpin")
@onready var allow_spectators_check = create_room_dialog.get_node("PanelContainer/VBoxContainer/AllowSpectatorsCheckBox")
@onready var visibility_option = create_room_dialog.get_node("PanelContainer/VBoxContainer/VisibilityOption")
@onready var password_edit = create_room_dialog.get_node("PanelContainer/VBoxContainer/PasswordEdit")
@onready var create_button = create_room_dialog.get_node("PanelContainer/VBoxContainer/HBoxContainer/CreateButton")
@onready var cancel_button = create_room_dialog.get_node("PanelContainer/VBoxContainer/HBoxContainer/CancelButton")

func _ready():
	print("Lobby _ready() - connecting signal")
	RoomManager.rooms_updated.connect(_on_rooms_updated)
	
	# Avoid duplicate signal connections
	if not create_button.pressed.is_connected(_on_create_room_confirmed):
		create_button.pressed.connect(_on_create_room_confirmed)
	if not cancel_button.pressed.is_connected(_on_cancel_button_pressed):
		cancel_button.pressed.connect(_on_cancel_button_pressed)
	
	# Optional: hide password field initially if visibility not private
	visibility_option.item_selected.connect(_on_visibility_changed)
	_on_visibility_changed(visibility_option.selected)
		
	print("rooms_container node: ", rooms_container)
	RoomManager.fetch_public_rooms()
	
	# Initially hide the dialog
	create_room_dialog.visible = false
	# Also maybe set up a timer to refresh periodically
	
func _on_visibility_changed(index: int):
	# Assuming index 0 = public, 1 = private
	password_edit.visible = (index == 1)

func _on_rooms_updated(rooms):
	print("_on_rooms_updated called with ", rooms.size(), " rooms")
	# Clear existing entries
	for child in rooms_container.get_children():
		child.queue_free()
	print("Container cleared")
	
	for room in rooms:
		print("  Creating entry for: ", room["room_name"])
		var room_entry = preload("res://Client/Scenes/RoomEntry.tscn").instantiate()
		rooms_container.add_child(room_entry)
		room_entry.setup(room)
	print("Container now has ", rooms_container.get_child_count(), " children")
	rooms_container.update_minimum_size()  # Force layout update

func _on_create_room_button_pressed():
	create_room_dialog.visible = true

func _on_refresh_button_pressed() -> void:
	RoomManager.fetch_public_rooms()

func _on_cancel_button_pressed() -> void:
	create_room_dialog.visible = false

func _on_create_room_confirmed() -> void:
	var room_name = room_name_edit.text.strip_edges()
	if room_name.is_empty():
		RoomManager.show_message("Invalid Room", "Room name cannot be empty.")
		return
	
	var max_players = int(max_players_spin.value)
	var allow_spectators = allow_spectators_check.button_pressed
	var visibility = visibility_option.get_item_text(visibility_option.selected).to_lower()  # "public" or "private"
	var password = password_edit.text if visibility == "private" else ""
	
	if visibility == "private" and password.is_empty():
		RoomManager.show_message("Invalid Room", "Private rooms require a password")
		return
	
	RoomManager.create_room(room_name, max_players, allow_spectators, visibility, password)
	create_room_dialog.visible = false
	
	# Optionally clear fields for next time
	room_name_edit.text = ""
	password_edit.text = ""
