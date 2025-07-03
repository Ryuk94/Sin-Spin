extends Node2D

var favor = 0

func increase_favor(amount):
	favor += amount
	if favor >= 100:
		if Global.adultMode:
			play_erotic_animation()
		else:
			play_teasing_animation()

func play_erotic_animation():
	# Play explicit animation
	pass

func play_teasing_animation():
	# Play mild tease animation
	pass
