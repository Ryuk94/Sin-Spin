extends RichTextLabel

var fade_timer := 0.0
var fade_duration := 2.0  # seconds
var jitter_timer := 0.0
var jitter_interval := 1.0 / 6.0  # fake 6 FPS movement
var target_opacity := 1.0

func _ready():
	self.modulate.a = 0.0  # start transparent
	self.visible_characters = -1
	set_process(true)

func _process(delta):
	# Fade in
	if fade_timer < fade_duration:
		fade_timer += delta
		var alpha = clamp(fade_timer / fade_duration, 0.0, 1.0)
		self.modulate.a = alpha * target_opacity

	# Jitter movement
	jitter_timer += delta
	if jitter_timer >= jitter_interval:
		jitter_timer = 0.0
		var x_jitter = randi() % 3 - 1
		var y_jitter = randi() % 3 - 1
		self.set_position(Vector2(640 + x_jitter, 360 + y_jitter))  # adjust to your resolution center
