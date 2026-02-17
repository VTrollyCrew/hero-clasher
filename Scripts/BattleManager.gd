extends Node

var battle_timer
var empty_character_card_slots = []
# This will be changed later to empty character card slot

var CARD_SIZE_REDUCE_SCALE = 0.7
var CARD_MOVE_SPEED = 0.2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	battle_timer = $"../BattleTimer"
	battle_timer.one_shot = true
	battle_timer.wait_time = 1.0
	
	# To store the monster card slots
	# This will be changed later
	empty_character_card_slots.append($"../CardSlots/OpponentCardSlot1")
	empty_character_card_slots.append($"../CardSlots/OpponentCardSlot2")
	empty_character_card_slots.append($"../CardSlots/OpponentCardSlot3")
	empty_character_card_slots.append($"../CardSlots/OpponentCardSlot4")
	empty_character_card_slots.append($"../CardSlots/OpponentCardSlot5")

func opponent_turn():
	$"../EndTurnButton".disabled = true
	$"../EndTurnButton".visible = false
	
	# To give a opponent thinking appearance
	battle_timer.start()
	await battle_timer.timeout
	
	if $"../OpponentDeck".opponent_deck.size() != 0:
		$"../OpponentDeck".draw_card()
		battle_timer.start()
		await battle_timer.timeout
	
	# Check any available character zones. If not, end turn
	if empty_character_card_slots.size() == 0:
		end_opponent_turn()
		return
	
	# Opponent play card
	# Note that there is a timer to wait until the opponent is finished
	await try_play_card_with_highest_attack()
	
	# End opponent turn
	end_opponent_turn()
	
func try_play_card_with_highest_attack():
	# For now, let opponent play a card with the highest attack
	# Later, change this effect
	var opponent_hand = $"../OpponentHand".opponent_hand
	if opponent_hand.size() == 0:
		end_opponent_turn()
		return
		
	# This section takes an empty character card slot and place character cards there
	var random_empty_character_card_slot = empty_character_card_slots[randi_range(0, empty_character_card_slots.size() - 1)]
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
	
	# To give a opponent thinking appearance
	battle_timer.start()
	await battle_timer.timeout

func end_opponent_turn():
	# Reset player deck draw
	$"../Deck".reset_draw()
	$"../CardManager".reset_played_character()
	$"../EndTurnButton".disabled = false
	$"../EndTurnButton".visible = true

func _on_end_turn_button_pressed() -> void:
	opponent_turn()
