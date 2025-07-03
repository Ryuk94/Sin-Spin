extends Control

func _ready():
	$CenterContainer/NewDayDisplay.text = "[center][wave amp=10 freq=5]Day %d. The horrors persist and so does your debt[/wave][/center]" % (Global.current_day + 1)
	$AutoContinueTimer.start()

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed:
		_on_continue_button_pressed()

func _on_AutoContinueTimer_timeout():
	_on_continue_button_pressed()

func _on_continue_button_pressed():
	Global.winnings = 0
	Global.current_day += 1
	Global.used_escape_clause = false
	Global.reset_upgrades()
	get_tree().change_scene_to_file("res://scenes/MainGame.tscn")
