# Card Manager must be modified to match the targetted deck format
# Refer to written documentation
extends Node2D

const COLLISION_MASK_CARD = 1
const COLLISION_MASK_CARD_SLOT = 2
const DEFAULT_CARD_MOVE_SPEED = 0.1
const DEFAULT_CARD_SCALE = 0.75
const CARD_HIGHLIGHT_SCALE = 0.8
const CARD_SMALLER_SCALE = 0.7

var screen_size
var card_being_dragged
var is_hovering_on_card
var player_hand_reference
var player_played_character_card_this_turn = false
# This is going to replace as player_played_item_cards_this_turn and limit the number of item usage
# This is connected to the deck. Make sure to modify the deck for that
# There are only two types of cards
# Characters, and items

var selected_character

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	screen_size = get_viewport_rect().size
	player_hand_reference = $"../PlayerHand"
	$"../InputManager".connect("left_mouse_button_released", on_left_click_released)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if card_being_dragged:
		var mouse_position = get_global_mouse_position()
		card_being_dragged.position = Vector2(clamp(mouse_position.x, 0, screen_size.x), clamp(mouse_position.y, 0, screen_size.y))
		# This makes the card follow the mouse in click and prevnt the card going out of bounds
		
func card_clicked(card):
	if card.card_is_in_card_slot:			# This checks whether the card clicked is in a card slot, confirming it is in the play zone
		if $"../BattleManager".is_opponent_turn == false:
			if $"../BattleManager".player_declared_attack == false:
				if card not in $"../BattleManager".player_characters_attacked_this_turn:
					if $"../BattleManager".opponent_character_cards_on_field.size() == 0:
						$"../BattleManager".direct_attack(card, "Player")
						return
					else:
						select_card_to_declare_attack(card)
	else:
		start_drag(card)
		
func select_card_to_declare_attack(card):
	# Toggle selected card
	if selected_character:
		# If the card is already selected
		if selected_character == card:
			card.position.y += 20
			selected_character = null
		else:
			selected_character.position.y += 20
			selected_character = card
			card.position.y -= 20
	else:
		selected_character = card
		card.position.y -= 20
			
func start_drag(card):
	card_being_dragged = card
	card.scale = Vector2(DEFAULT_CARD_SCALE, DEFAULT_CARD_SCALE)
	
func finish_drag():
	card_being_dragged.scale = Vector2(DEFAULT_CARD_SCALE, DEFAULT_CARD_SCALE)
	var card_slot_found = player_check_for_card_slot()
	if card_slot_found and not card_slot_found.card_in_slot:
		# Check if the card is a character card (This will be enhanced later)
		if card_being_dragged.card_type == card_slot_found.card_slot_type:
			if !player_played_character_card_this_turn:
				# Card dropped in slot
				player_played_character_card_this_turn = true
				card_being_dragged.scale = Vector2(CARD_SMALLER_SCALE, CARD_SMALLER_SCALE)
				card_being_dragged.z_index = -1
				is_hovering_on_card = false
				card_being_dragged.card_is_in_card_slot = card_slot_found
				player_hand_reference.remove_card_from_hand(card_being_dragged)
				# Card being dragged into a empty card slot
				card_being_dragged.position = card_slot_found.position
				card_slot_found.card_in_slot = true
				card_slot_found.get_node("Area2D/CollisionShape2D").disabled = true
				$"../BattleManager".player_character_cards_on_field.append(card_being_dragged)
				card_being_dragged = null
				return
	player_hand_reference.add_card_to_hand(card_being_dragged, DEFAULT_CARD_MOVE_SPEED)
	card_being_dragged = null
	
func deselect_selected_character():
	if selected_character:
		selected_character.position.y += 20
		selected_character = null

func connect_card_signals(card):
	card.connect("hovered", on_hovered_over_card)
	card.connect("hovered_off", on_hovered_off_card)
	
func on_left_click_released():
	if card_being_dragged:
		finish_drag()
	
func on_hovered_over_card(card):
	# This checks whether thecard is already in a card slot
	if card.card_is_in_card_slot:
		return
	
	#This checks whether the mouse is hovering over the card
	if !is_hovering_on_card:
		is_hovering_on_card = true
		highlight_card(card, true)
	
func on_hovered_off_card(card):
	#is_hovering_on_card = false
	# There is an issue when placing just this line, it won't hover to the next card immediately
	
	# To check if that card is recognized as defeated
	if !card.defeated:
		# Check card is not in the card slot and not being dragged
		if !card.card_is_in_card_slot && !card_being_dragged:
			highlight_card(card, false)
			var new_card_hovered = player_check_for_cards()
			if new_card_hovered:
				highlight_card(new_card_hovered, true)
			else:
				is_hovering_on_card = false

func highlight_card(card, hovered):
	if hovered:
		card.scale = Vector2(CARD_HIGHLIGHT_SCALE, CARD_HIGHLIGHT_SCALE)
		card.z_index = 2
	else:
		card.scale = Vector2(DEFAULT_CARD_SCALE, DEFAULT_CARD_SCALE)
		card.z_index = 1
			
func player_check_for_card_slot():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	# The above section is to return whatever is under the cursor
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_CARD_SLOT
	var result = space_state.intersect_point(parameters)
	
	if result.size() > 0:
		#return result[0].collider.get_parent()
		return result[0].collider.get_parent()
		# This line to give the card clicked
	return null			

func player_check_for_cards():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	# The above section is to return whatever is under the cursor
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_CARD
	var result = space_state.intersect_point(parameters)
	
	if result.size() > 0:
		#return result[0].collider.get_parent()
		return get_card_with_highest_z_index(result)
		# This line to give the card clicked
	return null

func get_card_with_highest_z_index(cards):
	# This assummes that the first card comes out of the list is the card with the highest z index
	var highest_z_card = cards[0].collider.get_parent()
	var highest_z_index = highest_z_card.z_index
	
	# Loop through the cards to look for the card with the highest z index
	for i in range(1, cards.size()):
		var current_card = cards[i].collider.get_parent()
		if current_card.z_index > highest_z_index:
			highest_z_card = current_card
			highest_z_index = current_card.z_index
	return highest_z_card
	
func reset_played_character():
	player_played_character_card_this_turn = false
