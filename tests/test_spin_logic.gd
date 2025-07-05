extends Node


func _ready():
	var slot_logic = preload("res://scripts/systems/spin_logic.gd").new()
	var outcome = slot_logic.evaluate(["Cash", "Cash", "Cash"])
	assert(outcome.winnings > 0)

	outcome = slot_logic.evaluate(["Cash", "Whip", "Heels"])
	assert(outcome.winnings == 0)
