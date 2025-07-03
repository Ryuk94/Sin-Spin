extends Node2D

signal spin_started
signal spin_completed(winnings)

const WinLine = preload("res://scenes/WinLine.tscn")
const HeartBurst = preload("res://scenes/HeartBurst.tscn")
const ICONS = ["Purple", "Whip", "Cash", "Elixir", "Heels"]
const ICON_PATH = "res://assets/images/Slots/Icons/%s.png"
const ICONS_PER_REEL = 3
const ICON_VALUES = {
	"Purple": 1,
	"Whip": 2,
	"Cash": 3,
	"Elixir": 4,
	"Heels": 5,
}

enum SlotUIState { PURCHASE, SPIN_READY, HIDDEN }

@onready var reels := [$Reels/Reel1, $Reels/Reel2, $Reels/Reel3, $Reels/Reel4]
@onready var ui := get_node("/root/MainGame/UI")
@onready var win_lines: Array[Line2D] = []

func _ready():
	randomize()
	set_ui_state(SlotUIState.HIDDEN)
	_initialize_reels()
	_on_spin_amount_box_value_changed($SpinPurchaseUI/SpinPurchase/SpinAmountBox.value)

func set_ui_state(state: SlotUIState):
	$SpinPurchaseUI.visible = state == SlotUIState.PURCHASE
	$Reels.visible = state != SlotUIState.PURCHASE and state != SlotUIState.HIDDEN
	$Spin.visible = state == SlotUIState.SPIN_READY

func reset():
	clear_win_lines()
	set_ui_state(SlotUIState.HIDDEN)

func show_spin_purchase_ui():
	set_ui_state(SlotUIState.PURCHASE)

func hide_purchase_ui():
	set_ui_state(SlotUIState.SPIN_READY)

func show_spin_button():
	$Spin.visible = true
	_on_spin_amount_box_value_changed($SpinPurchaseUI/SpinPurchase/SpinAmountBox.value)

func _initialize_reels():
	for reel in reels:
		_fill_reel(reel)

func _fill_reel(reel: Node):
	reel.get_children().map(func(c): c.queue_free())
	for i in range(ICONS_PER_REEL):
		var icon = _create_random_icon()
		_setup_icon(icon)
		reel.add_child(icon)

func _setup_icon(icon: TextureRect):
	icon.size_flags_vertical = Control.SIZE_EXPAND_FILL
	icon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	icon.custom_minimum_size = Vector2(128, 128)

func _create_random_icon() -> TextureRect:
	var icon_name = ICONS[randi() % ICONS.size()]
	return _create_icon(icon_name)

func _create_icon(icon_name: String) -> TextureRect:
	var icon_texture = load(ICON_PATH % icon_name)
	var icon = TextureRect.new()
	icon.texture = icon_texture
	icon.expand = true
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.set_meta("icon_name", icon_name)
	_setup_icon(icon)
	return icon

func _on_spin_amount_box_value_changed(value: float) -> void:
	var final_cost = calculate_spin_cost(value)
	var cost_label = $SpinPurchaseUI/SpinPurchase/SpinCostLabel
	cost_label.text = "Total cost: %d coins" % final_cost
	if Global.coins < final_cost:
		cost_label.add_theme_color_override("font_color", Color.RED)
	else:
		cost_label.remove_theme_color_override("font_color")

func calculate_spin_cost(spins: int) -> int:
	var total_spin_cost = max(1, int(Global.debt * 0.1))
	var cost_per_spin = max(1, int(ceil(float(total_spin_cost) / 8)))
	return cost_per_spin * spins

func _on_spin_purchase_button_pressed():
	var amount = $SpinPurchaseUI/SpinPurchase/SpinAmountBox.value
	var final_cost = calculate_spin_cost(amount)
	if Global.coins < final_cost:
		print("Not enough coins to buy spins!")
		return
	get_node("/root/MainGame").buy_spins(amount)
	set_ui_state(SlotUIState.SPIN_READY)

func spin():
	emit_signal("spin_started")
	print("Spinning...")

	for reel in reels:
		reel.get_children().map(func(c): c.queue_free())
	await get_tree().process_frame

	for reel in reels:
		for i in range(ICONS_PER_REEL):
			var icon = _create_random_icon()
			_setup_icon(icon)
			reel.add_child(icon)
	await get_tree().process_frame

	_inject_luck_symbols(get_icon_grid())
	await get_tree().create_timer(1.0).timeout

	var grid = get_icon_grid()
	var result = check_wins(grid)
	var matches = result["matches"]
	var payout = result["payout"]

	if Global.multiplier <= 0:
		Global.multiplier = 1
	payout *= Global.multiplier

	if "greed_dividend" in Global.bought_upgrades:
		var bonus = int(Global.debt / 50)
		print("Greed Dividend triggered: +%d coins bonus" % bonus)
		payout += bonus

	if "hex_hand" in Global.bought_upgrades:
		var losing_reels := _get_losing_reels(matches)
		if losing_reels.size() > 0:
			var reroll_index: int = losing_reels[randi() % losing_reels.size()]
			print("Hex’s Hand triggered: rerolling reel %d" % reroll_index)

			for child in reels[reroll_index].get_children():
				child.queue_free()
			await get_tree().process_frame

			for i in range(ICONS_PER_REEL):
				var icon = _create_random_icon()
				_setup_icon(icon)
				reels[reroll_index].add_child(icon)
			await get_tree().process_frame

			grid = get_icon_grid()
			var new_result = check_wins(grid)
			matches = new_result["matches"]
			payout = new_result["payout"] * Global.multiplier

	highlight_matches(matches)
	emit_signal("spin_completed", payout)
	ui.update_ui(Global.coins, Global.debt, Global.tickets, Global.spins_left)

func get_icon_grid() -> Array:
	var grid = []  # 3 rows, 4 columns
	for y in range(ICONS_PER_REEL):
		var row_data = []
		for x in range(reels.size()):
			var reel = reels[x]
			if reel.get_child_count() > y:
				var icon_node = reel.get_child(y) as TextureRect
				var icon_name = icon_node.get_meta("icon_name", "")
				row_data.append(icon_name)
			else:
				row_data.append("")
		grid.append(row_data)
	return grid

func check_wins(grid: Array) -> Dictionary:
	var matches = []
	var total_payout = 0

	for y in range(3):
		for x in range(2):
			if grid[y][x] != "" and grid[y][x] == grid[y][x + 1] and grid[y][x] == grid[y][x + 2]:
				matches.append([Vector2(x, y), Vector2(x + 1, y), Vector2(x + 2, y)])
				total_payout += 3 * ICON_VALUES.get(grid[y][x], 0)

	for y in range(3):
		if grid[y][0] != "" and grid[y][0] == grid[y][1] and grid[y][0] == grid[y][2] and grid[y][0] == grid[y][3]:
			matches.append([Vector2(0, y), Vector2(1, y), Vector2(2, y), Vector2(3, y)])
			total_payout += 4 * ICON_VALUES.get(grid[y][0], 0)

	for x in range(4):
		if grid[0][x] != "" and grid[0][x] == grid[1][x] and grid[0][x] == grid[2][x]:
			matches.append([Vector2(x, 0), Vector2(x, 1), Vector2(x, 2)])
			total_payout += 3 * ICON_VALUES.get(grid[0][x], 0)

	var diag3 = [
		[Vector2(0, 0), Vector2(1, 1), Vector2(2, 2)],
		[Vector2(1, 0), Vector2(2, 1), Vector2(3, 2)],
		[Vector2(0, 2), Vector2(1, 1), Vector2(2, 0)],
		[Vector2(1, 2), Vector2(2, 1), Vector2(3, 0)],
	]
	for path in diag3:
		var names = [grid[path[0].y][path[0].x], grid[path[1].y][path[1].x], grid[path[2].y][path[2].x]]
		if names[0] != "" and names[0] == names[1] and names[1] == names[2]:
			matches.append(path)
			total_payout += 3 * ICON_VALUES.get(names[0], 0)

	return {
		"matches": matches,
		"payout": total_payout
	}

func _get_losing_reels(matches: Array) -> Array:
	var winning_reels := []
	for match in matches:
		for point in match:
			if not winning_reels.has(point.x):
				winning_reels.append(point.x)
	var all_reels := [0, 1, 2, 3]
	return all_reels.filter(func(i): return !winning_reels.has(i))

func _inject_luck_symbols(grid: Array):
	var luck_count = clamp(Global.luck, 0, 12)
	if luck_count == 0:
		return
	var chosen_icon = ICONS[randi() % ICONS.size()]
	var empty_positions = []
	for y in range(3):
		for x in range(reels.size()):
			empty_positions.append(Vector2i(x, y))
	empty_positions.shuffle()
	for i in range(min(luck_count, empty_positions.size())):
		var pos = empty_positions[i]
		var reel = reels[pos.x]
		var new_icon = _create_icon(chosen_icon)
		var old_icon = reel.get_child(pos.y)
		if old_icon:
			old_icon.queue_free()
		reel.add_child(new_icon)
		reel.move_child(new_icon, pos.y)

func highlight_matches(matches: Array):
	clear_win_lines()
	for match in matches:
		var line = WinLine.instantiate()
		add_child(line)
		win_lines.append(line)
		var line_points: Array[Vector2] = []
		for point in match:
			var reel = reels[point.x]
			var icon = reel.get_child(point.y)
			var global_pos = icon.get_global_position() + icon.size * 0.5
			line_points.append(global_pos)
		animate_line(line, line_points)

func clear_win_lines():
	for line in win_lines:
		line.queue_free()
	win_lines.clear()

func animate_line(line: Line2D, points: Array[Vector2]) -> void:
	line.clear_points()
	call_deferred("_draw_line_points", line, points)

func _draw_line_points(line: Line2D, points: Array[Vector2]) -> void:
	var delay := 0.05
	for point in points:
		line.add_point(line.to_local(point))
		await get_tree().create_timer(delay).timeout
	for i in 4:
		if points.size() >= 2:
			var index = randi() % (points.size() - 1)
			var a = points[index]
			var b = points[index + 1]
			var t = randf()
			var pos = a.lerp(b, t)
			await spawn_heart_at_global(pos)

func spawn_heart_at_global(global_pos: Vector2):
	if global_pos == Vector2.ZERO:
		print("❌ Skipping heart at zero position")
		return
	var heart = HeartBurst.instantiate()
	add_child(heart)
	await get_tree().process_frame
	heart.global_position = global_pos
	heart.start_pos = global_pos
	heart.duration = randf_range(1.2, 2.5)
