extends Node


func _ready():
	var greed = preload("res://scripts/upgrades/greed_dividend.gd").new()
	Global.debt = 150
	assert(greed.get_bonus_coins() == 3)  # 1 per 50 debt
