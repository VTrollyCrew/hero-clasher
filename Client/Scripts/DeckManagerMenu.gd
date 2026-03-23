extends Control

@onready var deck_container = $MarginContainer/VBoxContainer/ScrollContainer/DeckContainer
@onready var options_popup = $DeckOptionsPopup

var deck_item_scene = preload("res://Client/Scenes/UI/DeckItem.tscn")

func _ready():
	# Connect DeckManager signals
	DeckManager.decks_loaded.connect(_on_decks_loaded)
	DeckManager.deck_created.connect(_on_deck_created)
	DeckManager.deck_deleted.connect(_on_deck_deleted)
	DeckManager.error_occurred.connect(_on_error)
	print("✅ Signals connected in DeckManagerScene")			# Debug

	# Connect popup signals
	options_popup.edit_deck.connect(_on_edit_deck)
	options_popup.delete_deck.connect(_on_delete_deck)
	
	# Load decks
	refresh_decks()

func refresh_decks():
	print("🔄 Refreshing decks...")			# Debug
	DeckManager.list_decks()
	
func _on_decks_loaded(decks: Array):
	print("📦 Decks loaded, count: ", decks.size())		# Debug
	# Clear existing items
	for child in deck_container.get_children():
		child.queue_free()
		
	# Add "New Deck" button
	var new_deck_btn = Button.new()
	new_deck_btn.text = "+ New Deck"
	new_deck_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	new_deck_btn.pressed.connect(_on_new_deck_pressed)
	deck_container.add_child(new_deck_btn)
	
	# Add existing decks
	for deck in decks:
		var item = deck_item_scene.instantiate()
		item.setup(deck)
		item.pressed.connect(_on_deck_item_pressed.bind(item))
		deck_container.add_child(item)

func _on_new_deck_pressed():
	# Create a new deck, then navigate to deck builder
	DeckManager.create_deck("New Deck")
	
func _on_deck_created(deck: Dictionary):
	# After creation, go to deck builder with this deck's ID
	DeckManager.current_editing_deck_id = deck["id"]
	print("Created Deck :" + DeckManager.current_editing_deck_id) # Debug
	# Replace with your actual deck builder scene path
	# get_tree().change_scene_to_file("res://Client/Scenes/DeckBuilder.tscn")
	
func _on_deck_item_pressed(item):
	options_popup.set_deck(item.deck_data)
	# Show popup near the clicked button (global coordinates)
	var offset = Vector2i(10, 10)  # small offset to avoid covering the button
	options_popup.popup(Rect2i(Vector2i(item.global_position) + offset, Vector2i()))
	
func _on_edit_deck(deck_data):
	DeckManager.current_editing_deck_id = deck_data["id"]
	# Replace with your actual deck builder scene path
	# get_tree().change_scene_to_file("res://Client/Scenes/DeckBuilder.tscn")
	
func _on_delete_deck(deck_data):
	# Optional: add a confirmation dialog here
	DeckManager.delete_deck(deck_data["id"])
	
func _on_deck_deleted(deck_id: String):
	print("✅ _on_deck_deleted called for deck: ", deck_id) 		# Debug
	refresh_decks()
	
func _on_error(message: String):
	# Show error popup (you can reuse the popup system)
	print("Error: ", message)
	# You could instantiate a generic error popup here

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://Client/Scenes/MainMenu.tscn")
