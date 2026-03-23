extends Button

var deck_data: Dictionary

func setup(data: Dictionary):
	print("Setting up deck item with data: ", data)  # Debug
	deck_data = data
	$VBoxContainer/DeckName.text = data.get("name", "Unnamed")
	$VBoxContainer/CardCount.text = "Cards: " + str(data.get("card_count", 0))
	# Optionally set a placeholder texture for the deck image
