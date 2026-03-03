extends Control

@onready var username_label = $Control/UsernameLabel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
# Update the UI with the identity stored in AuthManager
	if AuthManager.is_logged_in:
		username_label.text = "Welcome, " + AuthManager.username
	else:
		username_label.text = "Welcome, Guest"


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
