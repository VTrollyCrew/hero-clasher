extends Control

@onready var all_grid = $VBoxContainer/MainArea/LeftPanel/ScrollContainer/AllCardsGrid
@onready var deck_grid = $VBoxContainer/MainArea/RightPanel/ScrollContainer/DeckCardsGrid
@onready var popup = $CardDetailsPopup
@onready var popup_cardname = $CardDetailsPopup/VBoxContainer/HBoxContainer/VBoxContainer/CardName
@onready var popup_cardtype = $CardDetailsPopup/VBoxContainer/HBoxContainer/VBoxContainer/CardType
@onready var popup_cardattack = $CardDetailsPopup/VBoxContainer/HBoxContainer/VBoxContainer/CardAttack
@onready var popup_cardhealth = $CardDetailsPopup/VBoxContainer/HBoxContainer/VBoxContainer/CardHealth
@onready var popup_cardability = $CardDetailsPopup/VBoxContainer/HBoxContainer/VBoxContainer/CardAbilityText

var cardUIscene = preload("res://Client/Scenes/UI/CardUI.tscn")
var current_deck_id: String
var deck_cards: Array = []   # list of card names currently in deck

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	current_deck_id = DeckManager.current_editing_deck_id
	if current_deck_id.is_empty():
		get_tree().change_scene_to_file("res://Client/Scenes/DeckManager.tscn")
		return

	# Load deck data from PocketBase
	load_deck_data()

	# Populate all cards from database
	populate_all_cards()

	# Enable drag & drop
	deck_grid.allow_drop = true
	deck_grid.drop_data.connect(_on_drop_on_deck_grid)
	# Root accepts drops for removal
	self.allow_drop = true
	self.drop_data.connect(_on_drop_on_root)

func load_deck_data():
	var url = AuthManager.BACKEND_URL + "/api/collections/decks/records/" + current_deck_id
	var headers = ["Authorization: " + AuthManager.auth_token]
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_deck_loaded)
	http.request(url, headers, HTTPClient.METHOD_GET)

func _on_deck_loaded(result, code, headers, body):
	if code != 200:
		push_error("Failed to load deck")
		return
	var json = JSON.parse_string(body.get_string_from_utf8())
	deck_cards = json.get("cards", [])
	populate_deck_cards()
	
func populate_all_cards():
	for card_name in CardDatabase.CARDS:
		var data = CardDatabase.CARDS[card_name]
		var card_ui = cardUIscene.instantiate()
		card_ui.setup(card_name, data)
		card_ui.pressed.connect(_on_card_pressed.bind(card_ui))
		all_grid.add_child(card_ui)
		
func populate_deck_cards():
	# Clear existing
	for child in deck_grid.get_children():
		child.queue_free()

	for card_name in deck_cards:
		var data = CardDatabase.CARDS.get(card_name)
		if not data:
			continue
		var card_ui = cardUIscene.instantiate()
		card_ui.setup(card_name, data)
		card_ui.pressed.connect(_on_card_pressed.bind(card_ui))
		deck_grid.add_child(card_ui)

func _on_card_pressed(card_ui):
	# Show popup with details
	var data = card_ui.card_data
	popup_cardname.text = card_ui.card_name
	popup_cardtype.text = "Type: " + data[2]
	if data[2] == "Character":
		popup_cardattack.text = "ATK: " + str(data[0])
		popup_cardhealth.text = "HP: " + str(data[1])
		popup_cardattack.show()
		popup_cardhealth.show()
	else:
		popup_cardattack.hide()
		popup_cardhealth.hide()
	popup_cardability.text = "Ability: " + (data[3] if data[3] else "None")
	popup.popup_centered()

func _on_drop_on_deck_grid(pos, data):
	# If dropped from all_grid, add to deck
	if data.source.get_parent() == all_grid:
		var card_name = data.card_name
		# Optional: check if deck is full, duplicates allowed per your spec
		var card_data = CardDatabase.CARDS[card_name]
		var new_card = cardUIscene.instantiate()
		new_card.setup(card_name, card_data)
		new_card.pressed.connect(_on_card_pressed.bind(new_card))
		deck_grid.add_child(new_card)
		deck_cards.append(card_name)
		
func _on_drop_on_root(pos, data):
	# If source is from deck_grid, remove it
	if data.source.get_parent() == deck_grid:
		var card_name = data.card_name
		data.source.queue_free()
		deck_cards.erase(card_name)
		
func _on_save_button_pressed():
	var url = AuthManager.BACKEND_URL + "/api/collections/decks/records/" + current_deck_id
	var body = JSON.stringify({"cards": deck_cards})
	var headers = ["Content-Type: application/json", "Authorization: " + AuthManager.auth_token]
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_save_completed)
	http.request(url, headers, HTTPClient.METHOD_PATCH, body)
	
func _on_save_completed(result, code, headers, body):
	if code == 200:
		get_tree().change_scene_to_file("res://Client/Scenes/DeckManager.tscn")
	else:
		# Show error (could use your popup system)
		push_error("Failed to save deck")

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://Client/Scenes/DeckManager.tscn")

func _on_close_popup_pressed():
	popup.hide()
