extends Node

var clicks: Array[AudioStream] = []
var rollovers: Array[AudioStream] = []
var switches: Array[AudioStream] = []
var misc: Dictionary = {}  # e.g., "mouseclick1", "mouserelease1"

@onready var click_player = $ClickPlayer
@onready var rollover_player = $RolloverPlayer
@onready var switch_player = $SwitchPlayer
@onready var music_player = $MusicPlayer


func _ready() -> void:
	load_sounds()
	# Increase volume for UI sounds and music
	click_player.volume_db = 10  # Increased volume further
	rollover_player.volume_db = 10  # Increased volume further
	switch_player.volume_db = 10  # Increased volume further
	music_player.volume_db = 10  # Increased volume further


func load_sounds() -> void:
	var base_path := "res://assets/sounds/ui/"

	# Clicks
	for i in range(1, 6):
		var path := base_path + "click%d.ogg" % i
		var stream := load(path)
		if stream:
			clicks.append(stream)

	# Rollovers
	for i in range(1, 7):
		var path := base_path + "rollover%d.ogg" % i
		var stream := load(path)
		if stream:
			rollovers.append(stream)

	# Switches
	for i in range(1, 39):
		var path := base_path + "switch%d.ogg" % i
		var stream := load(path)
		if stream:
			switches.append(stream)

	# Misc
	var mouse_sfx = ["mouseclick1", "mouserelease1"]
	for sfx_name in mouse_sfx:
		var path := base_path + "%s.ogg" % sfx_name
		var stream := load(path)
		if stream:
			misc[sfx_name] = stream


func play_click() -> void:
	if clicks.size() > 0:
		click_player.stream = clicks.pick_random()
		click_player.play()


func play_rollover() -> void:
	if rollovers.size() > 0:
		rollover_player.stream = rollovers.pick_random()
		rollover_player.play()


func play_switch() -> void:
	if switches.size() > 0:
		switch_player.stream = switches.pick_random()
		switch_player.play()


func play_misc(sfx_name: String) -> void:
	if misc.has(sfx_name):
		switch_player.stream = misc[sfx_name]
		switch_player.play()
