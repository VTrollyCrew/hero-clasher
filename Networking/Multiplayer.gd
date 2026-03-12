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

func host_game():
	peer.create_server(PORT)
	multiplayer.multiplayer_peer = peer
	print("Server Started...")
	# Change scene to the actual Game Field or Waiting Room
	#get_tree().change_scene_to_file("res://Client/Scenes/GameField.tscn")
	
func join_game(address):
	peer.create_client(address, PORT)
	multiplayer.multiplayer_peer = peer
	print("Connecting to Host...")
	#get_tree().change_scene_to_file("res://Client/Scenes/GameField.tscn")

@rpc("authority", "call_local", "reliable")
func start_game_rpc():
	print("RPC Received: Starting Game...")
	# Replace with your actual game scene path
	#get_tree().change_scene_to_file("res://Client/Scenes/MainGameField.tscn")

func start_game_for_all():
	if multiplayer.is_server():
		# This sends the command to all connected peers
		start_game_rpc.rpc()
	else:
		print("Only the host can start the game!")
