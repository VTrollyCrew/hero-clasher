extends Node2D

const CARD_SCENE_PATH = "res://Scenes/Card.tscn"
# This is the card scene path
const CARD_DRAW_SPEED = 0.2
# This is the speed of the card draw
const STARTING_HAND_SIZE = 3

var player_deck = ["Knight", "Archer", "BlueSlime", "Demon", "Demon", "RedSlime", "RedSlime", "Knight", "Archer", "GreenSlime"]
# This is where the deck is saved. 
# For now, give temporary values
var card_database_reference
var is_card_drawn_this_turn = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player_deck.shuffle()
	$RichTextLabel.text = str(player_deck.size())
	# This returns how many cards are left in the deck
	card_database_reference = preload("res://Scripts/CardDatabase.gd")
	for i in range(STARTING_HAND_SIZE):
		draw_card()
		is_card_drawn_this_turn = false
	is_card_drawn_this_turn = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func draw_card():
	#print("Draw Card") 
	# For debugging
	if is_card_drawn_this_turn:
		return
	
	is_card_drawn_this_turn = true
	var card_drawn_name = player_deck[0]
	player_deck.erase(card_drawn_name)
	
	# This is to the scenario when the last card of the deck is drawn
	if player_deck.size() == 0:
		$Area2D/CollisionShape2D.disabled = true
		$Sprite2D.visible = false
		$RichTextLabel.visible = false
		
	$RichTextLabel.text = str(player_deck.size())
	
	var card_scene = preload(CARD_SCENE_PATH)
	var new_card = card_scene.instantiate()
	# instantiate() buils a new card object out of the pre loaded cards
	
	var card_image_path = str("res://Resources/Cards/" + card_drawn_name + "Card.png")
	new_card.get_node("CardImage").texture = load(card_image_path)
	# This reads the image using the patterned name method and load the image asset
	
	new_card.health = card_database_reference.CARDS[card_drawn_name][0]
	new_card.attack = card_database_reference.CARDS[card_drawn_name][1]
	new_card.card_type = card_database_reference.CARDS[card_drawn_name][2]
	# This loads the details of the card from the CardDatabase
	
	new_card.get_node("Attack").text = str(new_card.attack)
	new_card.get_node("Health").text = str(new_card.health)
	# This is for the richtext to display the data
	
	$"../CardManager".add_child(new_card)
	# This must be build as this way as it is mentioned it Card.gd where it is mentioned that the Card is a child of CardManager
	new_card.name = "Card"
	$"../PlayerHand".add_card_to_hand(new_card, CARD_DRAW_SPEED)
	new_card.get_node("AnimationPlayer").play("card_flip")

func reset_draw():
	is_card_drawn_this_turn = false
