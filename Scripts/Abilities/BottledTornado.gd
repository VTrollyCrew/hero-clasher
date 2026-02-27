# This script is not a direct child in the main node
# Due to this reason, the path references have to be given differently

# This is a Bottled Tornado exclusive card ability but can be recycled
# This will deal 1 damage to all opponent cards

extends Node

# Triggering time of the ability
const ABILITY_TRIGGERING_EVENT = "card_played"

var Tornado_DMG = 1

# This is set to trigger ability
# This will be heavily reused to other cards
func trigger_ability(battle_manager_reference, item_card_with_ability, input_manager_reference, trigger_event):
	#print("Ability Triggered")
	
	# Check the ability event trigger is matching with the received ability event trigger
	if ABILITY_TRIGGERING_EVENT != trigger_event:
		return
	
	# To disable inputs during trigger
	input_manager_reference.inputs_disabled = true
	
	# To disable the end turn button during the ability trigger
	battle_manager_reference.enabling_end_turn_button(false)
	
	# To keep timer
	await battle_manager_reference.wait(1.0)
	
	battle_manager_reference.rpc("sync_aoe_damage_to_opponent_field", Tornado_DMG)
	
	await battle_manager_reference.wait(1.0)
		
	# The card itself must be destroyed as well
	battle_manager_reference.destroy_card(item_card_with_ability, "Player")
	await battle_manager_reference.wait(1.0)
		
	# To enable the end turn button during the ability trigger
	battle_manager_reference.enabling_end_turn_button(true)
	input_manager_reference.inputs_disabled = false
