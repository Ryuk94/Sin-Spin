extends Control

func _ready():
	$CanvasLayer/NewDayDisplay.text = "[center][wave amp=10 freq=4]Day %d. The horrors persist and so does your debt[/wave][/center]" % Global.current_day

func _on_continue_button_pressed():
	Global.winnings = 0
	Global.used_escape_clause = false
	Global.reset_upgrades()
	
	get_tree().change_scene_to_file("res://scenes/MainGame.tscn")
