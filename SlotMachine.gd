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

@onready var reels := [$Reels/Reel1, $Reels/Reel2, $Reels/Reel3, $Reels/Reel4]

@onready var ui := get_node("/root/MainGame/UI")
@onready var win_lines: Array[Line2D] = []

enum SlotUIState { PURCHASE, SPIN_READY, HIDDEN }


func _ready():
	randomize()
	set_ui_state(SlotUIState.HIDDEN)
	_initialize_reels()
	_on_spin_amount_box_value_changed($SpinPurchaseUI/SpinPurchase/SpinAmountBox.value)
	_setup_spin_purchase_ui_style()  # Call new styling function


func _setup_spin_purchase_ui_style():
	# Adjust existing elements
	var spin_purchase = $SpinPurchaseUI/SpinPurchase
	spin_purchase.add_theme_constant_override("separation", 20)  # Increase spacing

	# Add a background style to the VBoxContainer itself
	spin_purchase.add_theme_stylebox_override("panel", StyleBoxFlat.new())
	var panel_style = spin_purchase.get_theme_stylebox("panel") as StyleBoxFlat
	panel_style.bg_color = Color(0.1, 0.1, 0.1, 0.7)  # Dark semi-transparent background
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.5, 0.5, 0.5, 1)  # Grey border
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_left = 10
	panel_style.corner_radius_bottom_right = 10
	panel_style.set_content_margin_all(10)  # Add some padding

	var spin_amount_box = $SpinPurchaseUI/SpinPurchase/SpinAmountBox
	spin_amount_box.add_theme_color_override("font_color", Color.WHITE)
	spin_amount_box.add_theme_color_override("font_readonly_color", Color.GRAY)
	spin_amount_box.add_theme_color_override("caret_color", Color.WHITE)
	spin_amount_box.add_theme_stylebox_override("normal", StyleBoxFlat.new())
	var spin_amount_box_style = spin_amount_box.get_theme_stylebox("normal") as StyleBoxFlat
	spin_amount_box_style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	spin_amount_box_style.border_width_left = 1
	spin_amount_box_style.border_width_top = 1
	spin_amount_box_style.border_width_right = 1
	spin_amount_box_style.border_color = Color(0.4, 0.4, 0.4, 1)
	spin_amount_box_style.corner_radius_top_left = 5
	spin_amount_box_style.corner_radius_top_right = 5
	spin_amount_box_style.corner_radius_bottom_left = 5
	spin_amount_box_style.corner_radius_bottom_right = 5

	var spin_purchase_button = $SpinPurchaseUI/SpinPurchase/SpinPurchaseButton
	spin_purchase_button.add_theme_color_override("font_color", Color.WHITE)
	spin_purchase_button.add_theme_stylebox_override("normal", StyleBoxFlat.new())
	var button_style = spin_purchase_button.get_theme_stylebox("normal") as StyleBoxFlat
	button_style.bg_color = Color(0.2, 0.5, 0.8, 1)  # Blue color
	button_style.border_width_left = 2
	button_style.border_width_top = 2
	button_style.border_width_right = 2
	button_style.border_color = Color(0.1, 0.3, 0.5, 1)
	button_style.corner_radius_top_left = 8
	button_style.corner_radius_top_right = 8
	button_style.corner_radius_bottom_left = 8
	button_style.corner_radius_bottom_right = 8
	spin_purchase_button.add_theme_stylebox_override("hover", button_style.duplicate())
	(spin_purchase_button.get_theme_stylebox("hover") as StyleBoxFlat).bg_color = Color(
		0.3, 0.6, 0.9, 1
	)
	spin_purchase_button.add_theme_stylebox_override("pressed", button_style.duplicate())
	(spin_purchase_button.get_theme_stylebox("pressed") as StyleBoxFlat).bg_color = Color(
		0.1, 0.4, 0.7, 1
	)
	spin_purchase_button.add_theme_stylebox_override("disabled", button_style.duplicate())
	(spin_purchase_button.get_theme_stylebox("disabled") as StyleBoxFlat).border_color = Color(
		0.1, 0.1, 0.1, 0.5
	)


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
		icon.position = Vector2(0, i * icon.custom_minimum_size.y)  # Set position
		var debug_string = "DEBUG: Spin Icon %d added to reel. Name: %s, " % [i, icon.get_meta("icon_name", "N/A")]
		debug_string += "Position: %s, Size: %s, Global Pos: %s, Global Scale: %s" % [icon.position, icon.size, icon.global_position, icon.get_global_transform().get_scale()]
		print(debug_string)
		reel.add_child(icon)


func _setup_icon(node: Control):  # Changed parameter type to Control
	node.size_flags_vertical = Control.SIZE_EXPAND_FILL
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.custom_minimum_size = Vector2(180, 180)  # Adjusted size based on image
	node.size = node.custom_minimum_size  # Ensure the control node has a size
	node.z_index = 10  # Set a high z_index to ensure visibility


func _create_random_icon() -> Control:  # Return type is now Control
	var icon_name = ICONS[randi() % ICONS.size()]
	return _create_icon(icon_name)


func _create_icon(icon_name: String, is_double: bool = false) -> Control:
	var container = Control.new()
	container.custom_minimum_size = Vector2(180, 180)  # Adjusted size based on image
	_setup_icon(container)  # Apply setup to the container itself

	var icon_texture = load(ICON_PATH % icon_name)
	var icon1 = TextureRect.new()
	icon1.texture = icon_texture
	icon1.expand = true
	icon1.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon1.set_meta("icon_name", icon_name)
	icon1.custom_minimum_size = Vector2(180, 180)  # Adjusted size based on image
	icon1.size_flags_vertical = Control.SIZE_EXPAND_FILL  # Explicitly set size flags
	icon1.size_flags_horizontal = Control.SIZE_EXPAND_FILL  # Explicitly set size flags
	container.add_child(icon1)

	if is_double:
		var icon2 = TextureRect.new()
		icon2.texture = icon_texture
		icon2.expand = true
		icon2.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon2.position = Vector2(10, 10)
		icon2.modulate = Color(1, 1, 1, 0.7)  # Make it slightly transparent
		icon2.custom_minimum_size = Vector2(180, 180)  # Adjusted size based on image
		icon2.size_flags_vertical = Control.SIZE_EXPAND_FILL  # Explicitly set size flags
		icon2.size_flags_horizontal = Control.SIZE_EXPAND_FILL  # Explicitly set size flags
		container.add_child(icon2)
		container.set_meta("is_double", true)

	container.set_meta("icon_name", icon_name)  # Ensure base icon name is always set
	print(
		"DEBUG: Created icon container '%s'. Z-index: %d, Icon1 Z-index: %d, Container Global Pos: %s, Container Global Scale: %s"
		% [
			icon_name,
			container.z_index,
			icon1.z_index,
			container.global_position,
			container.get_global_transform().get_scale()
		]
	)
	return container


func _on_spin_amount_box_value_changed(value: float) -> void:
	var final_cost = calculate_spin_cost(value)
	var cost_label = $SpinPurchaseUI/SpinPurchase/SpinCostLabel
	cost_label.text = "Total cost: %d coins" % final_cost
	print(
		"💰 Spin Purchase UI: Calculated cost for %.2f spins: %d coins (Global.spin_price_per_unit: %d)"
		% [value, final_cost, Global.spin_price_per_unit]
	)
	if Global.coins < final_cost:
		cost_label.add_theme_color_override("font_color", Color.RED)
		$SpinPurchaseUI/SpinPurchase/SpinPurchaseButton.disabled = true
	else:
		cost_label.remove_theme_color_override("font_color")
		$SpinPurchaseUI/SpinPurchase/SpinPurchaseButton.disabled = false


func calculate_spin_cost(spins: int) -> int:
	# Use the Global.spin_price_per_unit which is calculated in MainGame.gd
	return Global.spin_price_per_unit * spins


func _on_spin_purchase_button_pressed():
	var amount = $SpinPurchaseUI/SpinPurchase/SpinAmountBox.value
	var final_cost = calculate_spin_cost(amount)
	if Global.coins < final_cost:
		print("Not enough coins to buy spins!")
		return
	get_node("/root/MainGame").buy_spins(amount)
	set_ui_state(SlotUIState.SPIN_READY)
	UISoundManager.play_click()


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
			icon.position = Vector2(0, i * icon.custom_minimum_size.y)  # Set position
			var debug_string = "DEBUG: Spin Icon %d added to reel. Name: %s, " % [i, icon.get_meta("icon_name", "N/A")]
			debug_string += "Position: %s, Size: %s, Global Pos: %s, Global Scale: %s" % [icon.position, icon.size, icon.global_position, icon.get_global_transform().get_scale()]
			print(debug_string)
			reel.add_child(icon)
	await get_tree().process_frame

	await get_tree().create_timer(1.0).timeout

	var grid = get_icon_grid()
	var result = check_wins(grid)
	var matches = result["matches"]
	var payout = result["payout"]

	if Global.multiplier <= 0:
		Global.multiplier = 1
	payout *= int(Global.multiplier)

	if "greed_dividend" in Global.bought_upgrades:
		var bonus = int(Global.debt / 50)
		print("Greed Dividend triggered: +%d coins bonus" % bonus)
		payout += bonus

	# --- New Luck Logic ---
	if payout == 0 and Global.luck > 0:
		var luck_chance_per_point = 0.05  # 5% per luck point, so +2 luck = 10%
		var total_luck_chance = min(1.0, Global.luck * luck_chance_per_point)  # Cap at 100%
		print(
			(
				"🎲 Luck active! Global.luck: %d, Total Luck Chance: %.2f"
				% [Global.luck, total_luck_chance]
			)
		)

		if randf() < total_luck_chance:
			print("✨ Luck triggered a reroll attempt!")
			var best_reroll = _find_best_reroll(grid, matches)  # Use existing reroll logic
			if best_reroll["reel_index"] != -1:
				var reroll_index = best_reroll["reel_index"]
				var new_icons = best_reroll["new_icons"]
				print(
					(
						"✅ Luck Reroll: rerolling reel %d for a better outcome. New icons: %s"
						% [reroll_index, new_icons]
					)
				)

				if reels[reroll_index] and reels[reroll_index].get_child_count() > 0:
					for child in reels[reroll_index].get_children():
						child.queue_free()
					await get_tree().process_frame
				else:
					print(
						"⚠️ Luck Reroll: Reel %d is empty or invalid before reroll." % reroll_index
					)
					_fill_reel(reels[reroll_index])
					await get_tree().process_frame

				for i in range(ICONS_PER_REEL):
					var icon = _create_icon(new_icons[i])
					_setup_icon(icon)
					reels[reroll_index].add_child(icon)
				await get_tree().process_frame

				grid = get_icon_grid()
				var new_result = check_wins(grid)
				matches = new_result["matches"]
				payout = new_result["payout"] * int(Global.multiplier)
				print("✅ Luck Reroll completed. New payout: %d" % payout)
			else:
				print("❌ Luck Reroll: No beneficial reroll found.")
		else:
			print("❌ Luck did not trigger a reroll this spin.")
	# --- End New Luck Logic ---

	if "hex_hand" in Global.bought_upgrades:
		print("🔍 Hex's Hand: Checking for reroll opportunity.")
		var best_reroll = _find_best_reroll(grid, matches)
		if best_reroll["reel_index"] != -1:
			var reroll_index = best_reroll["reel_index"]
			var new_icons = best_reroll["new_icons"]
			print(
				(
					"✨ Hex’s Hand triggered: rerolling reel %d for a better outcome. New icons: %s"
					% [reroll_index, new_icons]
				)
			)

			# Ensure the reel exists and has children before attempting to free them
			if reels[reroll_index] and reels[reroll_index].get_child_count() > 0:
				for child in reels[reroll_index].get_children():
					child.queue_free()
				await get_tree().process_frame
			else:
				print("⚠️ Hex's Hand: Reel %d is empty or invalid before reroll." % reroll_index)
				# If the reel is unexpectedly empty, re-initialize it to prevent crashes
				_fill_reel(reels[reroll_index])
				await get_tree().process_frame

			for i in range(ICONS_PER_REEL):
				var icon = _create_icon(new_icons[i])
				_setup_icon(icon)
				reels[reroll_index].add_child(icon)
			await get_tree().process_frame

			grid = get_icon_grid()
			var new_result = check_wins(grid)
			matches = new_result["matches"]
			payout = new_result["payout"] * int(Global.multiplier)  # Ensure multiplier is int
			print("✅ Hex's Hand: Reroll completed. New payout: %d" % payout)
		else:
			print("❌ Hex's Hand triggered but no beneficial reroll found.")
	else:
		print("🚫 Hex's Hand not active.")

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
				var icon_node = reel.get_child(y) as Control  # Changed cast to Control
				var icon_name = icon_node.get_meta("icon_name", "")
				row_data.append(icon_name)
			else:
				row_data.append("")
		grid.append(row_data)
	return grid


# Helper to get icon name and its base value (potentially doubled)
func _get_icon_value_from_reel(x: int, y: int) -> int:
	var icon_node = reels[x].get_child(y)
	if not icon_node:  # Add null check
		return 0
	var icon_name = icon_node.get_meta("icon_name", "")
	var value = ICON_VALUES.get(icon_name, 0)
	if icon_node.has_meta("is_double") and icon_node.get_meta("is_double"):
		value *= 2
	return value


# Helper to get icon name for comparison
func _get_icon_name_for_comparison_from_reel(x: int, y: int) -> String:
	var icon_node = reels[x].get_child(y)
	if not icon_node:  # Add null check
		return ""
	return icon_node.get_meta("icon_name", "")


func check_wins(_grid: Array) -> Dictionary:  # Prefix grid with underscore
	var matches = []
	var total_payout = 0

	for y in range(3):
		for x in range(2):
			var name1 = _get_icon_name_for_comparison_from_reel(x, y)
			var name2 = _get_icon_name_for_comparison_from_reel(x + 1, y)
			var name3 = _get_icon_name_for_comparison_from_reel(x + 2, y)
			if name1 != "" and name1 == name2 and name2 == name3:
				matches.append([Vector2(x, y), Vector2(x + 1, y), Vector2(x + 2, y)])
				total_payout += int(
					(
						_get_icon_value_from_reel(x, y)
						+ _get_icon_value_from_reel(x + 1, y)
						+ _get_icon_value_from_reel(x + 2, y)
					)
				)

	for y in range(3):
		var name1 = _get_icon_name_for_comparison_from_reel(0, y)
		var name2 = _get_icon_name_for_comparison_from_reel(1, y)
		var name3 = _get_icon_name_for_comparison_from_reel(2, y)
		var name4 = _get_icon_name_for_comparison_from_reel(3, y)
		if name1 != "" and name1 == name2 and name2 == name3 and name3 == name4:
			matches.append([Vector2(0, y), Vector2(1, y), Vector2(2, y), Vector2(3, y)])
			total_payout += int(
				(
					_get_icon_value_from_reel(0, y)
					+ _get_icon_value_from_reel(1, y)
					+ _get_icon_value_from_reel(2, y)
					+ _get_icon_value_from_reel(3, y)
				)
			)

	for x in range(4):
		var name1 = _get_icon_name_for_comparison_from_reel(x, 0)
		var name2 = _get_icon_name_for_comparison_from_reel(x, 1)
		var name3 = _get_icon_name_for_comparison_from_reel(x, 2)
		if name1 != "" and name1 == name2 and name2 == name3:
			matches.append([Vector2(x, 0), Vector2(x, 1), Vector2(x, 2)])
			total_payout += int(
				(
					_get_icon_value_from_reel(x, 0)
					+ _get_icon_value_from_reel(x, 1)
					+ _get_icon_value_from_reel(x, 2)
				)
			)

	var diag3 = [
		[Vector2(0, 0), Vector2(1, 1), Vector2(2, 2)],
		[Vector2(1, 0), Vector2(2, 1), Vector2(3, 2)],
		[Vector2(0, 2), Vector2(1, 1), Vector2(2, 0)],
		[Vector2(1, 2), Vector2(2, 1), Vector2(3, 0)],
	]
	for path in diag3:
		var name1 = _get_icon_name_for_comparison_from_reel(path[0].x, path[0].y)
		var name2 = _get_icon_name_for_comparison_from_reel(path[1].x, path[1].y)
		var name3 = _get_icon_name_for_comparison_from_reel(path[2].x, path[2].y)
		if name1 != "" and name1 == name2 and name2 == name3:
			matches.append(path)
			total_payout += int(
				(
					_get_icon_value_from_reel(path[0].x, path[0].y)
					+ _get_icon_value_from_reel(path[1].x, path[1].y)
					+ _get_icon_value_from_reel(path[2].x, path[2].y)
				)
			)

	return {"matches": matches, "payout": total_payout}


func _get_losing_reels(matches: Array) -> Array:
	var winning_reels := []
	for match in matches:
		for point in match:
			if not winning_reels.has(point.x):
				winning_reels.append(point.x)
	var all_reels := [0, 1, 2, 3]
	return all_reels.filter(func(i): return !winning_reels.has(i))


func _simulate_reroll_and_check_win(
	current_grid: Array, reel_index: int, new_icons: Array
) -> Dictionary:
	var simulated_grid = current_grid.duplicate(true)  # Deep copy
	for y in range(ICONS_PER_REEL):
		if y < new_icons.size():
			simulated_grid[y][reel_index] = new_icons[y]
	return check_wins(simulated_grid)


func _find_best_reroll(original_grid: Array, original_matches: Array) -> Dictionary:
	var best_reroll = {"reel_index": -1, "new_icons": [], "payout": 0, "matches": []}
	var current_payout = check_wins(original_grid)["payout"]  # Prefix with underscore

	var losing_reels := _get_losing_reels(original_matches)
	if losing_reels.is_empty():
		return best_reroll  # No losing reels to reroll

	for reel_idx in losing_reels:
		for _i in range(5):  # Try multiple random sets of icons for the reel
			var potential_new_icons = []
			for y in range(ICONS_PER_REEL):
				potential_new_icons.append(ICONS[randi() % ICONS.size()])

			var simulated_result = _simulate_reroll_and_check_win(
				original_grid, reel_idx, potential_new_icons
			)
			var simulated_payout = simulated_result["payout"]
			var simulated_matches = simulated_result["matches"]

			# Ensure it doesn't stop a winning pattern (if there was one)
			if not original_matches.is_empty() and simulated_matches.is_empty():
				continue

			# Prioritize creating new wins or increasing payout
			if simulated_payout > best_reroll["payout"]:
				best_reroll["reel_index"] = reel_idx
				best_reroll["new_icons"] = potential_new_icons
				best_reroll["payout"] = simulated_payout
				best_reroll["matches"] = simulated_matches

	return best_reroll


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


func _on_spin_amount_box_changed() -> void:
	UISoundManager.play_click()
