extends Node2D

const CARD_SCENE_PATH = "res://Client/Scenes/OpponentCard.tscn"
# This is the card scene path
const CARD_DRAW_SPEED = 0.2
# This is the speed of the card draw
const STARTING_HAND_SIZE = 7

var opponent_deck = ["Knight", "BottledTornado", "BlueSlime", "Demon", "BottledTornado", "RedSlime", "RedSlime", "Knight", "Archer", "GreenSlime", "BottledTornado"]

# This is where the deck is saved. 
# For now, give temporary values
var card_database_reference

var deck_size: int = 11

@rpc("any_peer", "call_local")
func sync_initial_deck_size(size):
	deck_size = size
	$RichTextLabel.text = str(deck_size)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#opponent_deck.shuffle()
	#$RichTextLabel.text = str(opponent_deck.size())	# Will be initiated elsewhere
	# This returns how many cards are left in the deck
	card_database_reference = preload("res://Shared/Scripts/CardDatabase.gd")
	
	# This will be handled soon
	#for i in range(STARTING_HAND_SIZE):
		#draw_card()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func draw_card(name_of_drawn_card):
	#print("Draw Card") 
	# For debugging
	# 1. Initialize deck_size if it's null
	if typeof(deck_size) == TYPE_NIL:
		deck_size = 11
		
	# 2. Safety check for the label itself
	var deck_label = get_node_or_null("RichTextLabel")

	# This updates the deck size text and count
	if deck_size <= 1:
		self.visible = false
	else:
		deck_size -= 1
		
	# 3. Ensure we are passing a String, even if deck_size is weird
	if deck_label != null:
		var text_to_display = str(int(deck_size)) # Force it to Integer, then String
		if text_to_display != null:
			deck_label.text = text_to_display
	
	var card_scene = preload(CARD_SCENE_PATH)
	var new_card = card_scene.instantiate()
	# instantiate() buils a new card object out of the pre loaded cards
	
	var card_image_path = str("res://Resources/Cards/" + name_of_drawn_card + "Card.png")
	new_card.get_node("CardImage").texture = load(card_image_path)
	# This reads the image using the patterned name method and load the image asset
	
	new_card.card_type = card_database_reference.CARDS[name_of_drawn_card][2]
	var card_data = card_database_reference.CARDS[name_of_drawn_card]
	var ability_node = new_card.get_node("Ability")
	
	if new_card.card_type == "Character":
	# This checks whether the new card is a character
		# For now, this sets the visibility of the ability text to false
		# This will be modified later
		ability_node.text = str(card_data[3])
		ability_node.visible = false
		
		new_card.health = card_data[0]
		new_card.attack = card_data[1]
		# This loads the details of the card from the CardDatabase
		
		new_card.get_node("Attack").text = str(new_card.attack)
		new_card.get_node("Health").text = str(new_card.health)
		# This is for the richtext to display the data
	elif new_card.card_type == "Item":
	# This checks whether the new card is an item
		ability_node.text = str(card_data[3])
		ability_node.visible = false
		new_card.get_node("Attack").visible = false
		new_card.get_node("Health").visible = false
	else:
		pass
	
	$"../CardManager".add_child(new_card)
	# This must be build as this way as it is mentioned it Card.gd where it is mentioned that the Card is a child of CardManager
	new_card.name = "Card"
	$"../OpponentHand".add_card_to_hand(new_card, CARD_DRAW_SPEED)
