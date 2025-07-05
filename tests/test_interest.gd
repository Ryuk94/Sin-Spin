extends Node


func _ready():
	var interest = preload("res://scripts/systems/interest_calculator.gd").new()
	assert(interest.calculate_interest(100, 0.05) == 5)
	assert(interest.calculate_interest(0, 0.05) == 0)
	assert(interest.calculate_interest(200, 0.1) == 20)
