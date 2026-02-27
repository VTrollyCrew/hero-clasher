extends Node2D

# This holds the port info to be tested
const PORT = 3000

# This holds the server address
# If this is going to be deployed, place the server address here
const SERVER_ADDRESS = "localhost"

# This is to start establishing peer-to-peer connection
# Use E-Net Multiplayer library
var peer = ENetMultiplayerPeer.new()

# To instantiate the player fields for the process
@export var player_field_scene : PackedScene
@export var opponent_field_scene : PackedScene

func _on_host_button_pressed() -> void:
	disable_buttons()
	
	# Create server on assigned port for our multiplayer object 'peer' to listen
	peer.create_server(PORT)
	
	# 'multiplayer' is a built-in property in godot for all scenes can access
	# For matchmaking, 'multiplayer_peer' is used, which is responsible for the matchmaking process
	multiplayer.multiplayer_peer = peer
	
	# To test whether a player has joined
	multiplayer.peer_connected.connect(_on_peer_connected)
	
	var player_scene = player_field_scene.instantiate()
	add_child(player_scene)

func _on_join_button_pressed() -> void:
	disable_buttons()
	
	# This connects the user to the matchmaking room instead of making one
	peer.create_client(SERVER_ADDRESS, PORT)
	multiplayer.multiplayer_peer = peer 
	
	var player_scene = player_field_scene.instantiate()
	add_child(player_scene)
	
	# This is to instantiate the opponent scene
	var opponent_scene = opponent_field_scene.instantiate()
	add_child(opponent_scene)
	
	# This is for client side player field
	player_scene.client_set_up()

func _on_peer_connected(peer_id):
	print("Player Joined")
	# This is to instantiate the opponent scene
	var opponent_scene = opponent_field_scene.instantiate()
	add_child(opponent_scene)
	
	# This is to set player joined logic
	get_node("PlayerField").host_set_up()

# This is for the join and host button disabling
func disable_buttons():
	$HostButton.disabled = true
	$HostButton.visible = false
	$JoinButton.disabled = true
	$JoinButton.visible = false
