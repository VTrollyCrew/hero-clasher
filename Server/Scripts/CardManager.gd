# This is the Card manager server script
# This handles the logics involved in the card related function
# These functions include card instantiation to the game, card interactions (Drag, Drop, Selection, etc.) card slot interactions to designate card playing areas and more

# The basic game logic is heavily inspired by Barry's Dev Hell
# Playlist link: "https://www.youtube.com/playlist?list=PLNWIwxsLZ-LMYzxHlVb7v5Xo5KaUV7Tq1"

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
		if card in $"../BattleManager".player_characters_attacked_this_turn: # This checks whether the player attacked this turn
			return
			
		if card.card_type != "Character":
			return
		
		if $"../BattleManager".opponent_character_cards_on_field.size() == 0:
			$"../BattleManager".direct_attack(card)
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
	card.z_index = 100  # Always on top while dragging
	
	# Reset arc rotation
	card.rotation_degrees = 0
	
func finish_drag():
	card_being_dragged.scale = Vector2(DEFAULT_CARD_SCALE, DEFAULT_CARD_SCALE)
	var card_slot_found = player_check_for_card_slot()
	if card_slot_found and not card_slot_found.card_in_slot:
		# Check if the card is a character card (This will be enhanced later)
		if card_being_dragged.card_type == card_slot_found.card_slot_type:
			
			# Check whether the card is in the correct slot and player played character card this turn
			if card_being_dragged.card_type == "Character" && player_played_character_card_this_turn:
				player_hand_reference.add_card_to_hand(card_being_dragged, DEFAULT_CARD_MOVE_SPEED)
				card_being_dragged = null
				return
				
			# To collect the player ID to handle the set
			# By default, the host ID is 1. Any clients created are given a random set of numbers
			var player_id = multiplayer.get_unique_id()
				
			# To play card for player and client
			play_cards_in_slot_for_client_and_opponent(player_id, str(card_being_dragged.name), str(card_slot_found))
			rpc("play_cards_in_slot_for_client_and_opponent", player_id, str(card_being_dragged.name), str(card_slot_found))
			
			if card_being_dragged.card_type == "Character":
				$"../BattleManager".player_character_cards_on_field.append(card_being_dragged)
				player_played_character_card_this_turn = true
			
			if card_being_dragged.ability_script:
				card_being_dragged.ability_script.trigger_ability($"../BattleManager", card_being_dragged, $"../InputManager", "card_played")
				
			card_being_dragged = null
			return
			
	player_hand_reference.add_card_to_hand(card_being_dragged, DEFAULT_CARD_MOVE_SPEED)
	card_being_dragged = null
	
# This will be functioned to play cards for both player and opponnent
@rpc("any_peer")
func play_cards_in_slot_for_client_and_opponent(player_ID, card_name, card_slot_name):
	var card
	var card_slot
	
	if multiplayer.get_unique_id() == player_ID:
		# These are called only locally
		card = get_node(card_name)
		card_slot = $"../CardSlots".get_node(card_slot_name)
		
		is_hovering_on_card = false	
		player_hand_reference.remove_card_from_hand(card_being_dragged)
		card.position = card_slot.position
		card_slot.get_node("Area2D/CollisionShape2D").disabled = true
		
		if card.card_type == "Item":
			await get_tree().create_timer(1.5).timeout 			# Give time for the animation/ability
			$"../BattleManager".destroy_card(card, "Player")
	else:
		# This is the opponent side reflect
		var opponent_field_reference = get_parent().get_parent().get_node("OpponentField/")
		card = opponent_field_reference.get_node("CardManager/" + card_name)
		
		card_slot = opponent_field_reference.get_node("CardSlots/" + card_slot_name)
		opponent_field_reference.get_node("OpponentHand").remove_card_from_hand(card)
		
		var tween = get_tree().create_tween()
		tween.tween_property(card, "position", card_slot.position, DEFAULT_CARD_MOVE_SPEED)
		
		# Flip effect
		card.get_node("AnimationPlayer").play("card_flip")
		
		$"../BattleManager".opponent_character_cards_on_field.append(card)
		
		if card.card_type == "Item":
			await get_tree().create_timer(1.5).timeout
			$"../BattleManager".destroy_card(card, "Opponent")
		
	card.scale = Vector2(CARD_SMALLER_SCALE, CARD_SMALLER_SCALE)
	card.z_index = -1
	card.card_is_in_card_slot = card_slot
	card_slot.card_in_slot = true
	
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
	if card.card_is_in_card_slot:
		return
	
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
