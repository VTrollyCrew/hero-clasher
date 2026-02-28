# This script is not a direct child in the main node
# Due to this reason, the path references have to be given differently

# Double attack: This is an ability triggered after card declared attack. That card can attack twice

extends Node

# To check whether the ability has veen triggered
var has_activated = false

# Triggering time of the ability
const ABILITY_TRIGGERING_EVENT = "after_attack"

# This is set to trigger ability
# This will be heavily reused to other cards
func trigger_ability(battle_manager_reference, card_with_ability, input_manager_reference, trigger_event):
	#print("Ability Triggered. Attack Twice")		# For debugging purposes
	
	# Check the ability event trigger is matching with the received ability event trigger
	if ABILITY_TRIGGERING_EVENT != trigger_event:
		return
	
	# This checks whether the ability has already been activated
	if has_activated:
		return
	
	# This will remove the card from attacked list
	if card_with_ability in battle_manager_reference.player_characters_attacked_this_turn:
		battle_manager_reference.player_characters_attacked_this_turn.erase(card_with_ability)
		has_activated = true
		
# This is for end of turn ability reset
func end_turn_ability_reset():
	has_activated = false
