extends HBoxContainer

var room_data: Dictionary

@onready var name_label = $NameLabel
@onready var players_label = $PlayersLabel
@onready var join_button = $JoinButton

func setup(room):
	print("name_label: ", name_label)
	print("players_label: ", players_label)
	print("join_button: ", join_button)
	room_data = room
	name_label.text = room["room_name"]
	var players = room.get("all_players", []).size()
	var max_players = room.get("max_players", 2)
	players_label.text = str(players) + "/" + str(max_players)
	if room["visibility"] == "private":
		join_button.text = "Join (Private)"
	else:
		join_button.text = "Join"

func _on_join_button_pressed():
	if room_data["visibility"] == "private":
		# Show password dialog
		var password_dialog = preload("res://Client/Scenes/PasswordDialog.tscn").instantiate()
		add_child(password_dialog)
		password_dialog.popup_centered()
		password_dialog.password_entered.connect(_on_password_entered)
	else:
		RoomManager.join_room(room_data["id"])

func _on_password_entered(password):
	RoomManager.join_room(room_data["id"], password)
