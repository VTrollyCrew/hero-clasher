# This script is not a direct child in the main node
# Due to this reason, the path references have to be given differently

extends Node

var Tornado_DMG = 1

# This is set to trigger ability
# This will be heavily reused to other cards
func trigger_ability(battle_manager_reference, item_card_with_ability, input_manager_reference):
	#print("Ability Triggered")
	
	# To disable inputs during trigger
	input_manager_reference.inputs_disabled = true
	
	# To disable the end turn button during the ability trigger
	battle_manager_reference.enabling_end_turn_button(false)
	
	# To keep timer
	await battle_manager_reference.wait(1.0)
	
	# To keep destroyed cards
	var cards_to_be_destroyed = []
	
	# This checks all cards in that list
	for card in battle_manager_reference.opponent_character_cards_on_field:
		card.health = max(0, card.health - Tornado_DMG)
		card.get_node("Health").text = str(card.health)
		
		# Check whether the characters' health drop to 0
		if card.health == 0:
			cards_to_be_destroyed.append(card)
			
	await battle_manager_reference.wait(1.0)
	
	if cards_to_be_destroyed.size() > 0:
		for card in cards_to_be_destroyed:
			battle_manager_reference.destroy_card(card, "Opponent")
		
	battle_manager_reference.destroy_card(item_card_with_ability, "Player")
	await battle_manager_reference.wait(1.0)
		
	# To enable the end turn button during the ability trigger
	battle_manager_reference.enabling_end_turn_button(true)
	input_manager_reference.inputs_disabled = false
