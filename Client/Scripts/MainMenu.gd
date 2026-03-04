extends Control

@onready var username_label = $UserStats/UsernameLabel
@onready var connect_button = $UserStats/ConnectButton
@onready var vcoins_label = $UserStats/StatsLabel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if AuthManager.is_logged_in:
		username_label.text = "Welcome, " + AuthManager.username
		vcoins_label.text = "VCoins: " + str(AuthManager.vcoins)
			 
		# If already connected, change text and disable
		if AuthManager.is_vtrolly_connected:
			connect_button.text = "Vtrolly Linked ✅"
			connect_button.disabled = true
			connect_button.visible = true
		else:
			# If logged in but NOT connected, show the button to connect
			connect_button.text = "Connect Vtrolly"
			connect_button.disabled = false
			connect_button.visible = true
	else:
		# Guest mode
		username_label.text = "Guest"
		connect_button.visible = false
		
	# Connect to the update signal we just made
	AuthManager.user_data_updated.connect(_update_ui)
	_update_ui()

func _update_ui() -> void:
	if AuthManager.is_logged_in:
		username_label.text = "Welcome, " + AuthManager.username
		vcoins_label.text = "VCoins: " + str(AuthManager.vcoins)
		
		if AuthManager.is_vtrolly_connected:
			connect_button.text = "Vtrolly Linked ✅"
			connect_button.disabled = true
		else:
			connect_button.text = "Connect Vtrolly"
			connect_button.disabled = false
			connect_button.visible = true
	else:
		username_label.text = "Guest"
		vcoins_label.text = ""
		connect_button.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_play_button_pressed() -> void:
	# This will eventually trigger the matchmaking logic
	print("Searching for a battle...")
	# For now, let's just go to the old card scene to test
	get_tree().change_scene_to_file("res://Client/Scenes/CardTable.tscn")


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_connect_button_pressed() -> void:
	if not AuthManager.is_logged_in:
		AuthManager.show_message("Game Account Logins", "You must be logged into a Game Account before linking Vtrolly!")
		return
	
	get_tree().change_scene_to_file("res://Client/Scenes/ConnectToVTrolly.tscn")
