extends Node2D

@export var travel_distance: float = 40.0
@export var duration: float = 2.0
@export var fps: int = 6  # Fake low frame rate

var t: float = 0.0
var frame_timer: float = 0.0
var start_pos: Vector2 = Vector2.ZERO
var drift_angle: float
var alpha: float = 1.0

@onready var sprite: Sprite2D = get_node("Sprite2D")

func _ready():
	drift_angle = randf_range(-PI, PI)
	sprite.modulate = Color(1, 1, 1, 1)
	set_process(true)

func _process(delta: float) -> void:
	t += delta
	frame_timer += delta

	if t >= duration:
		queue_free()
		return

	# Simulate low-FPS update
	if frame_timer >= 1.0 / fps:
		frame_timer = 0.0

		var progress = t / duration
		var offset = Vector2.RIGHT.rotated(drift_angle) * travel_distance * progress
		var jitter = Vector2(randf_range(-3, 3), randf_range(-3, 3))

		global_position = start_pos + offset + jitter

	if t >= duration:
		queue_free()
		return

	if frame_timer >= 1.0 / fps:
		frame_timer = 0.0
		var progress = t / duration
		var offset = Vector2.RIGHT.rotated(drift_angle) * travel_distance * progress
		var jitter = Vector2(randf_range(-4, 4), randf_range(-4, 4))
		global_position = start_pos + offset + jitter
