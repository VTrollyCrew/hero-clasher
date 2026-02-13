extends Node2D

signal left_mouse_button_clicked
signal left_mouse_button_released

const COLLISION_MASK_CARD = 1
const COLLISION_MASK_DECK = 4

var card_manager_reference
var deck_reference

# This is a constant active function
func _ready() -> void:
	card_manager_reference = $"../CardManager"
	deck_reference = $"../Deck"

# Handle inputs
func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		#print("Click")
		if event.pressed:
			emit_signal("left_mouse_button_clicked")
			player_at_cursor()
		else:
			emit_signal("left_mouse_button_released")

func player_at_cursor():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	# The above section is to return whatever is under the cursor
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	#parameters.collision_mask = COLLISION_MASK_CARD
	var result = space_state.intersect_point(parameters)
	
	if result.size() > 0:
		var result_collision_mask = result[0].collider.collision_mask
		if result_collision_mask == COLLISION_MASK_CARD:
			# This checks the card click
			var card_found = result[0].collider.get_parent()
			if card_found:
				card_manager_reference.start_drag(card_found)
		elif result_collision_mask == COLLISION_MASK_DECK:
			# This checks the deck click
			deck_reference.draw_card()
