extends Button

var card_name: String
var card_data: Array   # [attack, health, type, ability_text, ability_script]

func setup(name_str: String, data: Array):
	card_name = name_str
	card_data = data
	$Attack.text = str(data[0]) if data[0] != null else ""
	$Health.text = str(data[1]) if data[1] != null else ""
	$Ability.text = data[3] if data[3] else ""
	# Set card art (adjust path as needed)
	# var texture = load("res://Assets/Cards/" + name_str + ".png")
	# if texture: $CardImage.texture = texture

# Drag support (built into Control)
func get_drag_data(at_position):
	var preview = duplicate()
	preview.modulate = Color(1,1,1,0.7)
	set_drag_preview(preview)
	return {"card_name": card_name, "source": self}
