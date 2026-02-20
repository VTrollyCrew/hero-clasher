# Card details are saved in the following order. This will be changed in the future
# "Card Name": {attack, health, card type, ability text, ability script}

const CARDS = {
	"Knight": [2, 2, "Character", null, null],
	"Demon": [3, 2, "Character", null, null],
	"Archer": [3, 1, "Character", null, null],
	"BlueSlime": [4, 1, "Character", null, null],
	"RedSlime": [4, 1, "Character", null, null],
	"GreenSlime": [3, 1, "Character", null, null],
	"BottledTornado": [null, null, "Item", "Deal 1 damage to all opponent characters", "res://Scripts/Abilities/BottledTornado.gd"]
}
# This is where the card information are saved.
# Note that this will be modified later
