# This is where the multiplayer game setup will be built
# Player data the game are managed in this section

# For the time being, 
extends Node2D

# This is the starting health
const STARTING_HEALTH = 10

# For host
func host_set_up():
	pass
	# These are tasks needed to be handled
	
	# Task 1: Setting player and opponent health
	$PlayerHealth.text = str(STARTING_HEALTH)
	get_parent().get_node("OpponentField/OpponentHealth").text = str(STARTING_HEALTH)
	$BattleManager.player_health = STARTING_HEALTH
	$BattleManager.opponent_health = STARTING_HEALTH
	
	# Task 2: Setting up deck text count and initial hand
	get_parent().get_node("OpponentField/OpponentDeck").deck_size = 11
	get_parent().get_node("OpponentField/OpponentDeck/RichTextLabel").text = "11"		# This will be autoloaded
	
	
	await $Deck.draw_starting_hand()
	
	# Task 3: Turn button visibility when conditions are met
	$EndTurnButton.visible = true
	$EndTurnButton.disabled = false
	
	# Task 4: Enabling input during turns
	$InputManager.inputs_disabled = false
	
# For client
func client_set_up():
	# Task 1: Setting player and opponent health
	$PlayerHealth.text = str(STARTING_HEALTH)
	get_parent().get_node("OpponentField/OpponentHealth").text = str(STARTING_HEALTH)
	$BattleManager.player_health = STARTING_HEALTH
	$BattleManager.opponent_health = STARTING_HEALTH
	
	# Task 2: Setting up deck text count and initial hand
	get_parent().get_node("OpponentField/OpponentDeck").deck_size = 11
	get_parent().get_node("OpponentField/OpponentDeck/RichTextLabel").text = "11"		# This will be autoloaded
	
	await $Deck.draw_starting_hand()
