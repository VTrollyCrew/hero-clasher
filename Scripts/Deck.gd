extends Node2D

const CARD_SCENE_PATH = "res://Scenes/card.tscn"
# This is the card scene path
const CARD_DRAW_SPEED = 0.2
# This is the speed of the card draw

var player_deck = ["Knight", "Archer", "BlueSlime", "Demon", "Demon", "RedSlime", "RedSlime", "Knight", "Archer", "GreenSlime"]
# This is where the deck is saved. 
# For now, give temporary values
var card_database_reference

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player_deck.shuffle()
	$RichTextLabel.text = str(player_deck.size())
	# This returns how many cards are left in the deck
	card_database_reference = preload("res://Scripts/CardDatabase.gd")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func draw_card():
	#print("Draw Card") 
	# For debugging
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
	var card_image_path = str("res://Resources/Cards/" + card_drawn_name + "Card.png")
	new_card.get_node("CardImage").texture = load(card_image_path)
	new_card.get_node("Attack").text = str(card_database_reference.CARDS[card_drawn_name][0])
	new_card.get_node("Health").text = str(card_database_reference.CARDS[card_drawn_name][1])
	$"../CardManager".add_child(new_card)
	# This must be build as this way as it is mentioned it Card.gd where it is mentioned that the Card is a child of CardManager
	new_card.name = "Card"
	$"../PlayerHand".add_card_to_hand(new_card, CARD_DRAW_SPEED)
	new_card.get_node("AnimationPlayer").play("card_flip")
