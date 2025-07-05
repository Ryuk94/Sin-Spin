extends Control

signal transition_finished


func _ready():
	# Update the day label immediately when the transition scene is ready
	$CenterContainer/NewDayDisplay.text = (
		"[center][wave amp=10 freq=5]Day %d. The horrors persist and so does your debt[/wave][/center]"
		% Global.current_day
	)
	$AutoContinueTimer.start()


func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed:
		_on_continue_button_pressed()


func _on_AutoContinueTimer_timeout():
	_on_continue_button_pressed()


func _on_continue_button_pressed():
	# Emit signal to notify MainGame that transition is finished
	transition_finished.emit()
	# Queue the current scene for deletion
	queue_free()
