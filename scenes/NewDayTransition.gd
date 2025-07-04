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
	# ✅ Preload and manually call next_round() before changing scenes
	var main_game_scene = preload("res://scenes/MainGame.tscn")
	var main_game = main_game_scene.instantiate()
	main_game.next_round()

	get_tree().change_scene_to_packed(main_game_scene)
