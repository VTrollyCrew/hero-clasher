extends Node2D

const HAND_COUNT = 10
# This will be changed later to 10 by the end of turn
const CARD_SCENE_PATH = "res://Scenes/card.tscn"
# This is the card scene path
const CARD_WIDTH = 160
const HAND_Y_POSITION = 890
# This will be adjusted accordingly

var player_hand = []
# This is the player hand

var center_screen_x

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	center_screen_x = get_viewport().size.x / 2
	
	var card_scene = preload(CARD_SCENE_PATH)
	for i in range(HAND_COUNT):
		var new_card = card_scene.instantiate()
		$"../CardManager".add_child(new_card)
		# This must be build as this way as it is mentioned it Card.gd where it is mentioned that the Card is a child of CardManager
		new_card.name = "Card"
		add_card_to_hand(new_card)

func add_card_to_hand(card):
	if card not in player_hand:
		player_hand.insert(0, card)
		update_hand_positions()
	else:
		animate_card_to_position(card, card.starting_position)
	
func update_hand_positions():
	for i in range(player_hand.size()):
		# This is to get the new cards in hands' position
		var new_position = Vector2(calculate_card_position(i), HAND_Y_POSITION)
		var card = player_hand[i]
		card.starting_position = new_position
		animate_card_to_position(card, new_position)
		
func calculate_card_position(index):
	var total_width = (player_hand.size() - 1) * CARD_WIDTH
	var x_offset = center_screen_x + index * CARD_WIDTH - total_width / 2
	return x_offset

# Called every frame. 'delta' is the elapsed time since the previous frame.
func animate_card_to_position(card, new_position):
	var tween = get_tree().create_tween()
	tween.tween_property(card, "position", new_position, 0.1)
	
func remove_card_from_hand(card):
	if card in player_hand:
		player_hand.erase(card)
		update_hand_positions()
