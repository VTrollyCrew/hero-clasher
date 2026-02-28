extends Node2D

# This is the card scene path
const CARD_SCENE_PATH = "res://Client/Scenes/Card.tscn"

const CARD_DATABASE_PATH = "res://Shared/Scripts/CardDatabase.gd"

# This is the speed of the card draw
const CARD_DRAW_SPEED = 0.2
# This is the starting hand count
const STARTING_HAND_SIZE = 7

var player_deck = ["Knight", "BottledTornado", "BlueSlime", "Demon", "BottledTornado", "RedSlime", "RedSlime", "Knight", "Archer", "GreenSlime", "BottledTornado"]
# This is where the deck is saved. 
# For now, give temporary values
var card_database_reference
var is_card_drawn_this_turn = false

# This is the deck specific timer
var deck_timer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player_deck.shuffle()

	# This returns how many cards are left in the deck
	card_database_reference = preload(CARD_DATABASE_PATH)
	
	# This will be handled soon
	#for i in range(STARTING_HAND_SIZE):
		#draw_card()
		#is_card_drawn_this_turn = false
	#is_card_drawn_this_turn = true
	
	# Initiating deck timer
	deck_timer = $DeckTimer
	deck_timer.one_shot = true
	deck_timer.wait_time = 1.0
	
func draw_starting_hand():
	# Wait for the network to actually be ready
	await get_tree().create_timer(0.5).timeout
	
	var size = player_deck.size()
	var opponent_deck = get_parent().get_parent().get_node_or_null("OpponentField/OpponentDeck")
	
# Only call RPC if we are actually connected and the node exists
	if opponent_deck and multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		opponent_deck.rpc("sync_initial_deck_size", size)
	
# Local update for the player's view of the opponent's deck
	if opponent_deck:
		opponent_deck.deck_size = size
		var opp_label = opponent_deck.get_node_or_null("RichTextLabel")
		if opp_label:
			opp_label.text = str(size)
	
	deck_timer.start()
	await deck_timer.timeout
	
	deck_timer.wait_time = 0.1
	
	# To collect the player ID to handle the set
	# By default, the host ID is 1. Any clients created are given a random set of numbers
	var player_id = multiplayer.get_unique_id()
	
	for i in range(STARTING_HAND_SIZE):
		var name_of_drawn_card = player_deck[0]
		draw_both_client_player_and_client_opponent(player_id, name_of_drawn_card)
		rpc("draw_both_client_player_and_client_opponent", player_id, name_of_drawn_card)
		is_card_drawn_this_turn = false
		
		deck_timer.start()
		await deck_timer.timeout
	is_card_drawn_this_turn = true
	
	# In order to proceed, the same must be replicated in the client opponent side as well
	
@rpc("any_peer")
func draw_both_client_player_and_client_opponent(Player_ID, name_of_drawn_card):
	# This is to check who is running the script
	if multiplayer.get_unique_id() == Player_ID:
		# To draw cards locally
		draw_card(name_of_drawn_card)
	else:
		# To draw cards to the clients
		get_parent().get_parent().get_node("OpponentField/OpponentDeck").draw_card(name_of_drawn_card)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func draw_card(name_of_drawn_card):
	#print("Draw Card") 
	# For debugging

	is_card_drawn_this_turn = true
	player_deck.erase(name_of_drawn_card)
	
	# This is to the scenario when the last card of the deck is drawn
	if player_deck.size() == 0:
		$Area2D/CollisionShape2D.disabled = true
		#$Sprite2D.visible = false
		#$RichTextLabel.visible = false
		visible = false
		
	$RichTextLabel.text = str(player_deck.size())
	
	var card_scene = preload(CARD_SCENE_PATH)
	var new_card = card_scene.instantiate()
	# instantiate() buils a new card object out of the pre loaded cards
	
	var card_image_path = str("res://Resources/Cards/" + name_of_drawn_card + "Card.png")
	new_card.get_node("CardImage").texture = load(card_image_path)
	# This reads the image using the patterned name method and load the image asset
	
	new_card.card_type = card_database_reference.CARDS[name_of_drawn_card][2]
	
	if new_card.card_type == "Character":
	# This checks whether the new card is a character
		# For now, this sets the visibility of the ability text to false
		
		new_card.health = card_database_reference.CARDS[name_of_drawn_card][0]
		new_card.attack = card_database_reference.CARDS[name_of_drawn_card][1]
		# This loads the details of the card from the CardDatabase
		
		new_card.get_node("Attack").text = str(new_card.attack)
		new_card.get_node("Health").text = str(new_card.health)
		# This is for the richtext to display the data
	elif new_card.card_type == "Item":
	# This checks whether the new card is an item
		new_card.get_node("Ability").visible = true
		new_card.get_node("Attack").visible = false
		new_card.get_node("Health").visible = false
	else:
		pass
	
	# Card ability related
	var new_card_ability_script_path = card_database_reference.CARDS[name_of_drawn_card][4]
	if new_card_ability_script_path:
		new_card.ability_script = load(new_card_ability_script_path).new()			# Instantiate
		new_card.get_node("Ability").text = card_database_reference.CARDS[name_of_drawn_card][3]
	else:
		new_card.get_node("Ability").visible = false
	
	$"../CardManager".add_child(new_card)
	# This must be build as this way as it is mentioned it Card.gd where it is mentioned that the Card is a child of CardManager
	new_card.name = "Card"
	$"../PlayerHand".add_card_to_hand(new_card, CARD_DRAW_SPEED)
	new_card.get_node("AnimationPlayer").play("card_flip")
	
func deck_clicked():
	if is_card_drawn_this_turn:
		return
		
	var name_of_drawn_card = player_deck[0]
	var player_id = multiplayer.get_unique_id()
	
	draw_both_client_player_and_client_opponent(player_id, name_of_drawn_card)
	rpc("draw_both_client_player_and_client_opponent", player_id, name_of_drawn_card)

func reset_draw():
	is_card_drawn_this_turn = false
