extends Node

enum GameState { SPINNING, ATM, SHOP, TRANSITION }
var current_state = GameState.SPINNING
var _is_processing_spin_completed = false  # New flag
@onready var ui: Node = $UI
@onready var slot_machine := $GameplayRoot/SlotMachine
@onready var shop := $SpendRoot/Shop
@onready var bedroom := $GameplayRoot/Bedroom


func _ready():
	DisplayServer.window_set_size(Vector2i(720, 1280))
	DisplayServer.window_set_position(Vector2i(3760, 80))

	await get_tree().process_frame  # wait for full tree init

	(
		SceneManager
		. setup(
			$GameplayRoot/Bedroom,
			{
				"ATM": $SpendRoot/ATM,
				"Shop": $SpendRoot/Shop,
				"SlotMachine": $GameplayRoot/SlotMachine,
			}
		)
	)

	setup_game()


func setup_game():
	Global.debt = calculate_debt_for_day(Global.current_day)
	if Global.multiplier <= 0:
		Global.multiplier = 1
	if slot_machine.spin_completed.is_connected(_on_spin_completed):
		slot_machine.spin_completed.disconnect(_on_spin_completed)
	slot_machine.spin_completed.connect(_on_spin_completed)
	var day_label = ui.get_node_or_null("Counters/DayLabel")
	if day_label:
		day_label.text = "Day: %d" % Global.current_day
	ui.update_ui(Global.coins, Global.debt, Global.tickets, Global.spins_left)
	shop.rotate_shop()
	switch_to_slot_machine()


func calculate_debt_for_day(day: int) -> int:
	var exponent = float(day - 1)
	return int(Global.base_debt * pow(Global.growth_factor, exponent))


func switch_to_slot_machine():
	current_state = GameState.SPINNING
	SceneManager.show_scene("SlotMachine", "Idle")
	ui.hide_atm()
	slot_machine.show_spin_purchase_ui()
	ui.update_ui(Global.coins, Global.debt, Global.tickets, Global.spins_left)


func switch_to_atm():
	Global.rounds_taken += 1
	current_state = GameState.ATM
	SceneManager.show_scene("ATM", "Money")
	ui.hide_spin_button()
	ui.show_atm()
	slot_machine.clear_win_lines()
	shop.open_shop()

	# Check for game over after 3 rounds if debt is not paid
	# Logic moved to _on_atm_close_button_pressed to allow player to attempt payment


func buy_spins(amount: int) -> void:
	var final_cost = Global.spin_price_per_unit * amount

	if Global.coins >= final_cost:
		Global.coins -= final_cost
		Global.spins_left = amount
		Global.winnings = 0  # reset winnings on new round
		ui.update_ui(Global.coins, Global.debt, Global.tickets, Global.spins_left)
		ui.show_spin_button()


func _on_spin_button_pressed():
	if Global.spins_left > 0:
		print("💥 Spin started. Spins left: %d" % Global.spins_left)
		Global.spins_left -= 1
		ui.update_spin_count(Global.spins_left)
		slot_machine.emit_signal("spin_started")
		slot_machine.spin()
		UISoundManager.play_click()

		if Global.spins_left == 0:
			current_state = GameState.TRANSITION
			print("DEBUG: Spin button pressed. Spins left is now 0. Setting state to TRANSITION.")


func _on_spin_completed(winnings: int):
	if _is_processing_spin_completed:
		print("DEBUG: _on_spin_completed re-entered, returning.")
		return

	_is_processing_spin_completed = true
	print(
		(
			"DEBUG: _on_spin_completed called. Global.spins_left: %d, current_state: %s"
			% [Global.spins_left, current_state]
		)
	)
	Global.coins += winnings
	Global.winnings += winnings
	print("🎰 Spin completed. Added winnings: %d | Total: %d" % [winnings, Global.winnings])
	ui.update_ui(Global.coins, Global.debt, Global.tickets, Global.spins_left)

	# Hex's Hack: 10% chance for an extra spin
	if "hex_hack" in Global.bought_upgrades and randf() < 0.1:  # 10% chance
		Global.spins_left += 1
		ui.update_spin_count(Global.spins_left)
		print("✨ Hex's Hack triggered! +1 extra spin.")

	if Global.spins_left == 0 and current_state == GameState.TRANSITION:
		print("DEBUG: Conditions met for ATM transition. Waiting 1.5s...")
		current_state = GameState.ATM  # Set state to ATM immediately to prevent re-entry
		await get_tree().create_timer(1.5).timeout
		Global.tickets += 1  # Player always gets a ticket at the end of a round
		ui.update_ui(Global.coins, Global.debt, Global.tickets, Global.spins_left)
		print("DEBUG: Calling switch_to_atm().")
		switch_to_atm()

	_is_processing_spin_completed = false  # Reset flag


func _on_deposit_pressed():
	if Global.coins <= 0 or Global.debt <= 0:
		print("⛔ Nothing to deposit.")
		return

	var deposit_amount = int(Global.coins * 0.25)
	deposit_amount = min(deposit_amount, Global.debt)

	Global.coins -= deposit_amount
	Global.debt -= deposit_amount

	UISoundManager.play_click()

	print(
		(
			"💸 Deposited %d coins. Remaining: %d | Debt: %d"
			% [deposit_amount, Global.coins, Global.debt]
		)
	)

	ui.update_ui(Global.coins, Global.debt, Global.tickets, Global.spins_left)

	# Check for Escape Clause only if game over is imminent
	var game_over_imminent = false
	if Global.coins < Global.spin_price_per_unit:  # Cannot afford next spin
		game_over_imminent = true
	if Global.rounds_taken == 2 and Global.debt > 0:  # About to hit 3-round game over
		game_over_imminent = true

	if (
		"escape_clause" in Global.bought_upgrades
		and Global.qualifies_for_escape_clause()
		and game_over_imminent
	):
		Global.used_escape_clause = true
		print("🎉 Escape Clause triggered to prevent game over!")
		_trigger_new_day_transition()
		return

	if Global.debt <= 0:
		_trigger_new_day_transition()


func _on_atm_close_button_pressed():
	if Global.debt <= 0:
		_trigger_new_day_transition()
	else:
		# Refined game over logic
		var trigger_game_over = false
		if Global.rounds_taken >= 3:
			if Global.debt > 0 or Global.coins < Global.spin_price_per_unit:
				trigger_game_over = true
		elif Global.coins < Global.spin_price_per_unit:  # Only check this if rounds_taken < 3
			trigger_game_over = true

		if trigger_game_over:
			game_over()
			return

		var day_label = ui.get_node_or_null("Counters/DayLabel")
		if day_label:
			day_label.text = "Day: %d" % Global.current_day
		ui.update_ui(Global.coins, Global.debt, Global.tickets, Global.spins_left)
		switch_to_slot_machine()
		UISoundManager.play_click()


func _trigger_new_day_transition():
	Global.current_day += 1  # Increment day before loading transition scene
	var new_day_transition_res = preload("res://scenes/NewDayTransition.tscn")
	var new_day_transition_instance = new_day_transition_res.instantiate()
	get_tree().get_root().add_child(new_day_transition_instance)
	new_day_transition_instance.transition_finished.connect(_on_new_day_transition_finished)


func _advance_game_day_logic():
	Global.rounds_taken = 0
	Global.winnings = 0

	# Only reset upgrades if escape clause was used
	if Global.used_escape_clause:
		Global.reset_upgrades()
		Global.used_escape_clause = false  # Reset for next day
		ui.show_escape_clause_popup()
		print("🔄 Upgrades reset due to Escape Clause.")

	Global.debt = calculate_debt_for_day(Global.current_day)
	var total_spin_cost = int(Global.debt * 0.1)
	Global.spin_price_per_unit = max(1, int(ceil(float(total_spin_cost) / 4)))  # Reverted to previous rate
	print(
		(
			"🎯 Spin price set for Day %d: %d coins per spin"
			% [Global.current_day, Global.spin_price_per_unit]
		)
	)

	if "debt_engine" in Global.bought_upgrades:
		var interest_bonus = int(Global.debt * (Global.interest_rate / 100.0) * 0.5)
		Global.coins += interest_bonus
		Global.total_interest_earned += interest_bonus  # Update total interest earned
		ui.show_interest_popup(interest_bonus)
		ui.update_total_interest_earned(Global.total_interest_earned)  # Update the new label
		print(
			(
				"⚙️ Debt Engine triggered: +%d coins from interest bonus. Total earned: %d"
				% [interest_bonus, Global.total_interest_earned]
			)
		)

	if "compound_suffering" in Global.bought_upgrades and Global.debt > 0:
		Global.interest_rate += 1
		print(
			"📈 Compound Suffering triggered: Interest rate increased to %f." % Global.interest_rate
		)

	match Global.rounds_taken:
		1:
			Global.tickets += 7
		2:
			Global.tickets += 6
		_:
			Global.tickets += 5

	# ✅ Corrected node access
	var counters = ui.get_node_or_null("Counters")
	if counters:
		var day_label = counters.get_node_or_null("DayLabel")
		if day_label:
			day_label.text = "Day: %d" % Global.current_day


func _on_new_day_transition_finished():
	# Advance game day logic
	_advance_game_day_logic()

	# Update UI and show game elements after transition
	ui.update_ui(Global.coins, Global.debt, Global.tickets, Global.spins_left)
	shop.rotate_shop()
	shop.open_shop()
	switch_to_slot_machine()
	slot_machine.set_ui_state(slot_machine.SlotUIState.PURCHASE)  # Show "Buy Spins" UI


func _on_game_over_restart_pressed():
	print("Restarting game...")
	get_tree().set_pause(false)  # Unpause before reloading
	get_tree().change_scene_to_file("res://scenes/MainGame.tscn")


func game_over():
	print("💀 Game Over!")
	ui.show_game_over_overlay()
	# Disable input to prevent further interaction with game elements
	get_tree().set_pause(true)  # Pause the game logic
	# Connect the restart button from the overlay
	var game_over_overlay_node = ui.get_node_or_null("GameOverOverlay")
	if game_over_overlay_node:
		var restart_button = game_over_overlay_node.get_node_or_null("VBoxContainer/RestartButton")
		if restart_button:
			if restart_button.pressed.is_connected(_on_game_over_restart_pressed):
				restart_button.pressed.disconnect(_on_game_over_restart_pressed)
			restart_button.pressed.connect(_on_game_over_restart_pressed)
