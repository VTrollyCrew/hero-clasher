extends Node

var battle_timer

# This will be changed later to empty character card slot
var empty_character_card_slots = []
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

# For opponents' turn check
var is_opponent_turn = false

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

func opponent_turn():
	$"../EndTurnButton".disabled = true
	$"../EndTurnButton".visible = false
	
	# To give a opponent thinking appearance
	await wait(1.0)
	
	if $"../OpponentDeck".opponent_deck.size() != 0:
		$"../OpponentDeck".draw_card()
		await wait(1.0)
	
	# Check any available character zones, and play characters with the highest attack
	if empty_character_card_slots.size() != 0:
		await try_play_card_with_highest_attack()
	
	# Opponent trys to attack
	if opponent_character_cards_on_field.size() != 0:
		var opponent_character_cards_to_attack =  opponent_character_cards_on_field.duplicate()
		for card in opponent_character_cards_to_attack:
			if player_character_cards_on_field.size() != 0:
				var card_to_attack = player_character_cards_on_field.pick_random()
				await attack(card, card_to_attack, "Opponent")
			else:
				await direct_attack(card, "Opponent")
	
	
	# End opponent turn
	end_opponent_turn()
	
# The direct attack function is not available for the future build as the game focus on character elimination style combat	
func direct_attack(attacking_card, attacker):
	var new_position_y
	if attacker == "Opponent":
		new_position_y = 1080
	else:
		enabling_end_turn_button(false)
		$"../InputManager".inputs_disabled = true
		new_position_y = 0
		player_characters_attacked_this_turn.append(attacking_card)
	
	var new_position = Vector2(attacking_card.position.x, new_position_y)
	
	attacking_card.z_index = 5
	# To render the attacking card above everything else
	
	var tween = get_tree().create_tween()
	tween.tween_property(attacking_card, "position", new_position, CARD_MOVE_SPEED)
	await wait(0.15)
	
	if attacker == "Opponent":
		player_health = max(0, player_health - attacking_card.attack)
		$"../PlayerHealth".text = str(player_health)
		# Deal damage to player
	else:
		opponent_health = max(0, opponent_health - attacking_card.attack)
		#$"../OpponentHealth".text = str(opponent_health)
		# Deal damage to opponent
	
	# Animete cards to position
	var tween2 = get_tree().create_tween()
	tween2.tween_property(attacking_card, "position", attacking_card.card_is_in_card_slot.position, CARD_MOVE_SPEED)
	
	attacking_card.z_index = 0
	# Note that the card_is_in_card_slot is in Card.gd
	await wait(1.0)
	
	if attacker == "Player":
		if attacking_card.ability_script:
			await attacking_card.ability_script.trigger_ability(self, attacking_card, $"../InputManager", "after_attack")
		enabling_end_turn_button(true)
		$"../InputManager".inputs_disabled = false
	
# The attack function will be modified later to use the attacking card abilities/basic attacks
# Basic attack is not defined properly in the structure yet, but will discuss
func attack(attacking_card, defending_card, attacker):
	# print("Attack") 
	# For testing purposes
	if attacker == "Player":
		enabling_end_turn_button(false)
		$"../InputManager".inputs_disabled = true
		$"../CardManager".selected_character = null
		player_characters_attacked_this_turn.append(attacking_card)
	
	attacking_card.z_index = 5
	var new_position = Vector2(defending_card.position.x, defending_card.position.y + BATTLE_POSITION_OFFSET)
	
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
		destroy_card(attacking_card, attacker)
		character_card_is_destroyed = true
	if defending_card.health == 0:
		if attacker == "Player":
			destroy_card(defending_card, "Opponent")
		else:
			destroy_card(defending_card, "Player")
		character_card_is_destroyed = true
		
	if character_card_is_destroyed:
		await wait(1.0)
		
	if attacker == "Player":
		if attacking_card.ability_script:
			await attacking_card.ability_script.trigger_ability(self, attacking_card, $"../InputManager", "after_attack")
		enabling_end_turn_button(true)
		$"../InputManager".inputs_disabled = false
	
func try_play_card_with_highest_attack():
	# For now, let opponent play a card with the highest attack
	# Later, change this effect
	var opponent_hand = $"../OpponentHand".opponent_hand
	if opponent_hand.size() == 0:
		end_opponent_turn()
		return
		
	# This section takes an empty character card slot and place character cards there
	var random_empty_character_card_slot = empty_character_card_slots.pick_random()
	empty_character_card_slots.erase(random_empty_character_card_slot)
	
	# Play the card with the highest attack
	# This will be changed later
	var character_card_with_highest_attack = opponent_hand[0]
	for card in opponent_hand:
		if card.attack > character_card_with_highest_attack.attack:
			character_card_with_highest_attack = card
	
	# Animate card into the card slot position
	var tween = get_tree().create_tween()
	tween.tween_property(character_card_with_highest_attack, "position", random_empty_character_card_slot.position, CARD_MOVE_SPEED)
	var tween2 = get_tree().create_tween()
	tween2.tween_property(character_card_with_highest_attack, "scale", Vector2(CARD_SIZE_REDUCE_SCALE, CARD_SIZE_REDUCE_SCALE), CARD_MOVE_SPEED)
	character_card_with_highest_attack.get_node("AnimationPlayer").play("card_flip")
	
	# Remove the card from the opponent hand
	$"../OpponentHand".remove_card_from_hand(character_card_with_highest_attack)
	character_card_with_highest_attack.card_is_in_card_slot = random_empty_character_card_slot
	
	opponent_character_cards_on_field.append(character_card_with_highest_attack)
	
	# To give a opponent thinking appearance
	await wait(1.0)

func end_opponent_turn():
	# Reset player deck draw
	$"../Deck".reset_draw()
	$"../CardManager".reset_played_character()
	is_opponent_turn = false
	$"../EndTurnButton".disabled = false
	$"../EndTurnButton".visible = true

func _on_end_turn_button_pressed() -> void:
	is_opponent_turn = true
	$"../CardManager".deselect_selected_character()
	
	# To check all attacked cards end turn abilities 
	for card in player_characters_attacked_this_turn:
		card.ability_script.end_turn_ability_reset()
	
	player_characters_attacked_this_turn = []
	opponent_turn()
	
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
		card.defeated = true
		card.get_node("Area2D/CollisionShape2D").disabled = true	
		new_position = $"../PlayerDiscard".position
		if card in player_character_cards_on_field:
			player_character_cards_on_field.erase(card)
		card.card_is_in_card_slot.get_node("Area2D/CollisionShape2D").disabled = false
	else:
		new_position = $"../OpponentDiscard".position
		if card in opponent_character_cards_on_field:
			opponent_character_cards_on_field.erase(card)
	
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
				attack(attacking_card, defending_card, "Player")

func enabling_end_turn_button(is_enabled):
	if is_enabled:
		$"../EndTurnButton".disabled = false
		$"../EndTurnButton".visible = true
	else:
		$"../EndTurnButton".disabled = true
		$"../EndTurnButton".visible = false
