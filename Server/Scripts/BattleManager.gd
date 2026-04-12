# This is the battle logic is designed
# All battle logic including life points, attacks, clashes, card interactions and button interactions are handled
# This is directly connected to the multiplayer RPC function. This connects the peers to interact with the players

# The basic game logic is heavily inspired by Barry's Dev Hell
# Playlist link: "https://www.youtube.com/playlist?list=PLNWIwxsLZ-LMYzxHlVb7v5Xo5KaUV7Tq1"

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
const STARTING_HEALTH = 10
var player_health
var opponent_health

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	battle_timer = $"../BattleTimer"
	battle_timer.one_shot = true
	battle_timer.wait_time = 1.0
	
@rpc("any_peer", "call_local")
func sync_direct_damage(damage, target_is_opponent: bool):
	# target_is_opponent: true if the player who CALLED the RPC is hitting their enemy
	# In multiplayer, 'opponent_health' for the sender is 'player_health' for the receiver.
	if multiplayer.get_unique_id() == multiplayer.get_remote_sender_id() or multiplayer.get_remote_sender_id() == 0:
		# Logic for the person who played the card
		opponent_health = max(0, opponent_health - damage)
		var opponent_label = get_parent().get_parent().get_node_or_null("OpponentField/OpponentHealth")
		if opponent_label:
			opponent_label.text = str(opponent_health)
	else:
		# Logic for the person receiving the hit
		player_health = max(0, player_health - damage)
		var player_label = get_node_or_null("../PlayerHealth")
		if player_label:
			player_label.text = str(player_health)
			
@rpc("any_peer", "call_local")
func sync_aoe_damage_to_opponent_field(damage):
	var cards_to_be_destroyed = []
	var targets
	
	# If I am the one who called this, I target the 'opponent_character_cards_on_field'
	# If I am the one receiving this, I target my OWN 'player_character_cards_on_field'
	if multiplayer.get_unique_id() == multiplayer.get_remote_sender_id() or multiplayer.get_remote_sender_id() == 0:
		targets = opponent_character_cards_on_field
	else:
		targets = player_character_cards_on_field

	# Apply damage to all targets in the list
	for card in targets:
		card.health = max(0, card.health - damage)
		card.get_node("Health").text = str(card.health)
		if card.health == 0:
			cards_to_be_destroyed.append(card)
			
	# Cleanup dead cards
	for card in cards_to_be_destroyed:
		var owner_label = "Opponent" if targets == opponent_character_cards_on_field else "Player"
		destroy_card(card, owner_label)
	
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
		
	# Save the return position NOW, before any 'awaits' happen
	if attacking_card == null or attacking_card.card_is_in_card_slot == null:
		return # Safety exit if the card doesn't exist or isn't in a slot
		
	var return_position = attacking_card.card_is_in_card_slot.position
		
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
	tween2.tween_property(attacking_card, "position", return_position, CARD_MOVE_SPEED)
	
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
	
	#player_attack_and_relay_attack_to_client_opponent(player_id, str(attacking_card.name), str(defending_card.name))
	rpc("player_attack_and_relay_attack_to_client_opponent", player_id, str(attacking_card.name), str(defending_card.name))
		
	if attacking_card.ability_script:
		await attacking_card.ability_script.trigger_ability(self, attacking_card, $"../InputManager", "after_attack")
	enabling_end_turn_button(true)
	$"../InputManager".inputs_disabled = false

@rpc("any_peer", "call_local")
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
		# ADD THIS CHECK: Only call if ability_script exists (is not Nil)
		if card.ability_script != null:
			card.ability_script.end_turn_ability_reset()
	
	player_characters_attacked_this_turn = []
	$"../CardManager".reset_played_character()
	
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
		# ONLY update slot if the card actually has one (Characters have them, Items might not)
		if card.card_is_in_card_slot != null:
			card.card_is_in_card_slot.get_node("Area2D/CollisionShape2D").disabled = false
	else:
		new_position = get_parent().get_parent().get_node("OpponentField/OpponentDiscard").position
		if card in opponent_character_cards_on_field:
			opponent_character_cards_on_field.erase(card)
	
	card.defeated = true
	
	# Safety check: Clear the slot reference only if it exists
	if card.card_is_in_card_slot != null:
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
