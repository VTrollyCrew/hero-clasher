# This is the players' hand
# This holds the cards of the players' hand and their animation. Only the player can view what the hand cards are and interact with them
# This script is attached to the PlayerHand node2D located in the PlayerField.tscn scene

# This coding is inspired by YouTuber "Barry's Dev Hell"
# Link: "https://www.youtube.com/watch?v=lATAS8YpzFE&list=PLNWIwxsLZ-LMYzxHlVb7v5Xo5KaUV7Tq1&index=4&pp=iAQB"

extends Node2D 

# const HAND_COUNT = 10 
# This will be changed later to 10 by the end of turn 

const CARD_WIDTH = 120 
const HAND_Y_POSITION = 990 
# This will be adjusted accordingly 

const DEFAULT_CARD_MOVE_SPEED = 0.1 

var player_hand = [] 
# This is the player hand 

var center_screen_x 
# Called when the node enters the scene tree for the first time. 

func _ready() -> void: 
	center_screen_x = get_viewport().size.x / 2 
	
func add_card_to_hand(card, speed): 
	if card not in player_hand: 
		player_hand.insert(0, card) 
		update_hand_positions(speed) 
	else: 
		animate_card_to_position(card, card.starting_position, DEFAULT_CARD_MOVE_SPEED) 
		
func update_hand_positions(speed): 
	for i in range(player_hand.size()): 
		# This is to get the new cards in hands' position 
		var new_position = Vector2(calculate_card_position(i), HAND_Y_POSITION) 
		var card = player_hand[i] 
		card.starting_position = new_position 
		animate_card_to_position(card, new_position, speed) 
		
func calculate_card_position(index): 
	var total_width = (player_hand.size() - 1) * CARD_WIDTH 
	var x_offset = center_screen_x - index * CARD_WIDTH + total_width / 2 
	return x_offset 
	
# Called every frame. 'delta' is the elapsed time since the previous frame. 
func animate_card_to_position(card, new_position, speed): 
	var tween = get_tree().create_tween() 
	tween.tween_property(card, "position", new_position, speed) 
	
func remove_card_from_hand(card): 
	if card in player_hand: 
		player_hand.erase(card) 
		update_hand_positions(DEFAULT_CARD_MOVE_SPEED)
