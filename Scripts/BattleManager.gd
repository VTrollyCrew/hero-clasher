extends Node

var battle_timer

# This will be changed later to empty character card slot
var opponent_character_cards_on_field = []
var player_character_cards_on_field = []
var player_characters_attacked_this_turn = []

# constant values for smoother operation
const CARD_SIZE_REDUCE_SCALE = 0.7
const CARD_MOVE_SPEED = 0.2
const BATTLE_POSITION_OFFSET = 25

# For health management
const STARTING_HEALTH = 10			# This will be removed later since this is a character battle system
var player_health
var opponent_health

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	battle_timer = $"../BattleTimer"
	battle_timer.one_shot = true
	battle_timer.wait_time = 1.0
	
	# The below units will be handled elsewhere
	#player_health = STARTING_HEALTH
	#$"../PlayerHealth".text = str(player_health)
	#opponent_health = STARTING_HEALTH
	#$"../OpponentHealth".text = str(opponent_health)
	
	# To store the character card slots
	# This will be changed later
	# These will be removed in the multiplayer
	#empty_character_card_slots.append($"../CardSlots/OpponentCardSlot1")
	#empty_character_card_slots.append($"../CardSlots/OpponentCardSlot2")
	#empty_character_card_slots.append($"../CardSlots/OpponentCardSlot3")
	#empty_character_card_slots.append($"../CardSlots/OpponentCardSlot4")
	#empty_character_card_slots.append($"../CardSlots/OpponentCardSlot5")
	
func direct_damage_to_opponent(damage):
	opponent_health = max(0, opponent_health - damage)
	#$"../OpponentHealth".text = str(opponent_health)
	
# The direct attack function is not available for the future build as the game focus on character elimination style combat	
func direct_attack(attacking_card):
	enabling_end_turn_button(false)
	$"../InputManager".inputs_disabled = true
	player_characters_attacked_this_turn.append(attacking_card)
	
	# To collect the player ID to handle the set
	# By default, the host ID is 1. Any clients created are given a random set of numbers
	var player_id = multiplayer.get_unique_id()
	
	# Calling direct attacks
	# Locally call it here
	rpc("player_direct_attack_and_relay_attack_to_client_opponent", player_id, str(attacking_card))
	await player_direct_attack_and_relay_attack_to_client_opponent(player_id, str(attacking_card))
	
	if attacking_card.ability_script:
		await attacking_card.ability_script.trigger_ability(self, attacking_card, $"../InputManager", "after_attack")
	enabling_end_turn_button(true)
	$"../InputManager".inputs_disabled = false
	
@rpc("any_peer")
func player_direct_attack_and_relay_attack_to_client_opponent(player_id, attacking_card_name):
	var attacking_card
	var attack_position_y
	
	if multiplayer.get_unique_id() == player_id:
		attacking_card = $"../CardManager".get_node(attacking_card_name)
		attack_position_y = 0
	else:
		attacking_card = get_parent().get_parent().get_node("OpponentField/CardManager/" + attacking_card_name)
		attack_position_y = 1080
		
	var new_position = Vector2(attacking_card.position.x, attack_position_y)
	
	attacking_card.z_index = 5
	# To render the attacking card above everything else
	
	var tween = get_tree().create_tween()
	tween.tween_property(attacking_card, "position", new_position, CARD_MOVE_SPEED)
	await wait(0.15)
	
	if multiplayer.get_unique_id() == player_id:
		opponent_health = max(0, opponent_health - attacking_card.attack)
		get_parent().get_parent().get_node("OpponentField/OpponentHealth").text = str(opponent_health)
		# Deal damage to opponent
	else:
		player_health = max(0, player_health - attacking_card.attack)
		$"../PlayerHealth".text = str(player_health)
		# Deal damage to player
	
	# Animete cards to position
	var tween2 = get_tree().create_tween()
	tween2.tween_property(attacking_card, "position", attacking_card.card_is_in_card_slot.position, CARD_MOVE_SPEED)
	
	attacking_card.z_index = 0
	# Note that the card_is_in_card_slot is in Card.gd
	await wait(1.0)

# The attack function will be modified later to use the attacking card abilities/basic attacks
# Basic attack is not defined properly in the structure yet, but will discuss
func attack(attacking_card, defending_card):
	# print("Attack") 
	# For testing purposes
	enabling_end_turn_button(false)
	$"../InputManager".inputs_disabled = true
	$"../CardManager".selected_character = null
	player_characters_attacked_this_turn.append(attacking_card)
	
	# To collect the player ID to handle the set
	# By default, the host ID is 1. Any clients created are given a random set of numbers
	var player_id = multiplayer.get_unique_id()
	
	player_attack_and_relay_attack_to_client_opponent(player_id, str(attacking_card.name), str(defending_card.name))
	rpc("player_attack_and_relay_attack_to_client_opponent", player_id, str(attacking_card.name), str(defending_card.name))
		
	if attacking_card.ability_script:
		await attacking_card.ability_script.trigger_ability(self, attacking_card, $"../InputManager", "after_attack")
	enabling_end_turn_button(true)
	$"../InputManager".inputs_disabled = false

@rpc("any_peer")
func player_attack_and_relay_attack_to_client_opponent(player_id, attacking_card_name, defending_card_name):
	# This is to hold the attacking card
	var attacking_card
	var defending_card
	var y_offset
	
	# This is to set the details locally
	if multiplayer.get_unique_id() == player_id:
		attacking_card = $"../CardManager".get_node(attacking_card_name)
		defending_card = get_parent().get_parent().get_node("OpponentField/CardManager/" + defending_card_name)
		y_offset = BATTLE_POSITION_OFFSET
	else:
		attacking_card = get_parent().get_parent().get_node("OpponentField/CardManager/" + attacking_card_name)
		defending_card = $"../CardManager".get_node(defending_card_name)
		y_offset = -BATTLE_POSITION_OFFSET
		
	
	attacking_card.z_index = 5
	var new_position = Vector2(defending_card.position.x, defending_card.position.y + y_offset)
	
	# Card moving animation
	var tween = get_tree().create_tween()
	tween.tween_property(attacking_card, "position", new_position, CARD_MOVE_SPEED)
	await wait(0.15)
	var tween2 = get_tree().create_tween()
	tween2.tween_property(attacking_card, "position", attacking_card.card_is_in_card_slot.position, CARD_MOVE_SPEED)
	
	# Damage dealing theory
	# This mechanic, both cards takes the clash approach
	# Note that this will be heavily modified
	defending_card.health = max(0, defending_card.health - attacking_card.attack)
	defending_card.get_node("Health").text = str(defending_card.health)
	attacking_card.health = max(0, attacking_card.health - defending_card.attack)
	attacking_card.get_node("Health").text = str(attacking_card.health)
	
	await wait(1.0)
	attacking_card.z_index = 0
	
	var character_card_is_destroyed = false
	# This is to check if character card is no longer having any health or is destroyed
	
	# This mechanic is to destroy cards when health drop to 0
	if attacking_card.health == 0:
		if multiplayer.get_unique_id() == player_id:
			destroy_card(attacking_card, "Player")
		else:
			destroy_card(attacking_card, "Opponent")
			
		character_card_is_destroyed = true
	if defending_card.health == 0:
		if multiplayer.get_unique_id() == player_id:
			destroy_card(defending_card, "Opponent")
		else:
			destroy_card(defending_card, "Player")
		character_card_is_destroyed = true
		
	if character_card_is_destroyed:
		await wait(1.0)

func _on_end_turn_button_pressed() -> void:
	enabling_end_turn_button(false)
	$"../InputManager".inputs_disabled = true
	
	$"../CardManager".deselect_selected_character()
	
	# To check all attacked cards end turn abilities 
	for card in player_characters_attacked_this_turn:
		card.ability_script.end_turn_ability_reset()
	
	player_characters_attacked_this_turn = []
	
	rpc("change_turn")
	
@rpc("any_peer")
func change_turn():
	$"../Deck".reset_draw()
	$"../CardManager".reset_played_character
	enabling_end_turn_button(true)
	$"../InputManager".inputs_disabled = false
	
func wait(wait_time):
	battle_timer.wait_time = wait_time
	battle_timer.start()
	await battle_timer.timeout

# This function is to destroy cards when health drop to 0
# This mechanic is most likely be in the final build
func destroy_card(card, card_owner):
	# This logic sends the destroyed card to discard pile
	# Additionally, any cards cards destroyed must be removed from their relevant card slot arrays
	# example: player_character_cards_on_field, opponent_character_cards_on_field
	var new_position
	if card_owner == "Player":
		card.get_node("Area2D/CollisionShape2D").disabled = true	
		new_position = $"../PlayerDiscard".position
		if card in player_character_cards_on_field:
			player_character_cards_on_field.erase(card)
		card.card_is_in_card_slot.get_node("Area2D/CollisionShape2D").disabled = false
	else:
		new_position = get_parent().get_parent().get_node("OpponentField/OpponentDiscard").position
		if card in opponent_character_cards_on_field:
			opponent_character_cards_on_field.erase(card)
	
	card.defeated = true
	
	card.card_is_in_card_slot.card_in_slot = false
	card.card_is_in_card_slot = null
	
	var tween = get_tree().create_tween()
	tween.tween_property(card, "position", new_position, CARD_MOVE_SPEED)
	await wait(0.15)

func opponent_card_selected(defending_card):
	var attacking_card = $"../CardManager".selected_character
	if attacking_card:
		if defending_card in opponent_character_cards_on_field:
			if $"../InputManager".inputs_disabled == false:
				$"../CardManager".selected_character = null
				attack(attacking_card, defending_card)

func enabling_end_turn_button(is_enabled):
	if is_enabled:
		$"../EndTurnButton".disabled = false
		$"../EndTurnButton".visible = true
	else:
		$"../EndTurnButton".disabled = true
		$"../EndTurnButton".visible = false
