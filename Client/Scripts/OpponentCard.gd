# This is the opponent cand data script
# This holds data of the opponents cards which were instantiated in the game
# This is attached to the OpponentCard.tscn scene

extends Node2D

# For card position handling
var starting_position
var card_is_in_card_slot

# For card details handling
var card_type
var health
var attack

# For card state
var defeated = false
