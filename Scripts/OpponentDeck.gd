extends Node2D

const CARD_SCENE_PATH = "res://Scenes/OpponentCard.tscn"
# This is the card scene path
const CARD_DRAW_SPEED = 0.2
# This is the speed of the card draw
const STARTING_HAND_SIZE = 7

var opponent_deck = ["Knight", "Archer", "BlueSlime", "Demon", "Demon", "RedSlime", "RedSlime", "Knight", "Archer", "GreenSlime"]
# This is where the deck is saved. 
# For now, give temporary values
var card_database_reference

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	opponent_deck.shuffle()
	$RichTextLabel.text = str(opponent_deck.size())
	# This returns how many cards are left in the deck
	card_database_reference = preload("res://Scripts/CardDatabase.gd")
	for i in range(STARTING_HAND_SIZE):
		draw_card()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func draw_card():
	#print("Draw Card") 
	# For debugging
		
	var card_drawn_name = opponent_deck[0]
	opponent_deck.erase(card_drawn_name)
	
	# This is to the scenario when the last card of the deck is drawn
	if opponent_deck.size() == 0:
		$Sprite2D.visible = false
		$RichTextLabel.visible = false
		
	$RichTextLabel.text = str(opponent_deck.size())
	
	var card_scene = preload(CARD_SCENE_PATH)
	var new_card = card_scene.instantiate()
	# instantiate() buils a new card object out of the pre loaded cards
	
	var card_image_path = str("res://Resources/Cards/" + card_drawn_name + "Card.png")
	new_card.get_node("CardImage").texture = load(card_image_path)
	# This reads the image using the patterned name method and load the image asset
	
	new_card.card_type = card_database_reference.CARDS[card_drawn_name][2]
	
	if new_card.card_type == "Character":
	# This checks whether the new card is a character
		# For now, this sets the visibility of the ability text to false
		# This will be modified later
		new_card.get_node("Ability").visible = false
		
		new_card.health = card_database_reference.CARDS[card_drawn_name][0]
		new_card.attack = card_database_reference.CARDS[card_drawn_name][1]
		# This loads the details of the card from the CardDatabase
		
		new_card.get_node("Attack").text = str(new_card.attack)
		new_card.get_node("Health").text = str(new_card.health)
		# This is for the richtext to display the data
	elif new_card.card_type == "Item":
	# This checks whether the new card is an item
		new_card.get_node("Ability").visible = true
		new_card.get_node("Attack").visible = false
		new_card.get_node("Health").visible = false
		new_card.get_node("Ability").text = card_database_reference.CARDS[card_drawn_name][3]
	else:
		pass
	
	$"../CardManager".add_child(new_card)
	# This must be build as this way as it is mentioned it Card.gd where it is mentioned that the Card is a child of CardManager
	new_card.name = "Card"
	$"../OpponentHand".add_card_to_hand(new_card, CARD_DRAW_SPEED)
