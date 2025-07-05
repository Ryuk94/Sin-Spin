extends Node

enum GameState { SPINNING, ATM, SHOP, TRANSITION }
var current_state = GameState.SPINNING

@onready var ui := $UI
@onready var slot_machine := $GameplayRoot/SlotMachine
@onready var shop := $SpendRoot/Shop
@onready var bedroom := $GameplayRoot/Bedroom

func _ready():
	DisplayServer.window_set_size(Vector2i(720, 1280))
	DisplayServer.window_set_position(Vector2i(3760, 80))
	SceneManager.setup(
		$GameplayRoot/Bedroom,
		{
			"ATM": $SpendRoot/ATM,
			"Shop": $SpendRoot/Shop,
			"SlotMachine": $GameplayRoot/SlotMachine,
		}
	)

	# One-time button hookup
	var _deposit_button = $SpendRoot/ATM/ATMButtons/Deposit
	var _close_button = $SpendRoot/ATM/ATMButtons/Close
	setup_game()

func setup_game():
	Global.debt = calculate_debt_for_day(Global.current_day)
	if Global.multiplier <= 0:
		Global.multiplier = 1
	slot_machine.spin_completed.connect(_on_spin_completed)
	ui.get_node("Counters/DayLabel").text = "Day: %d" % Global.current_day
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
	current_state = GameState.ATM
	SceneManager.show_scene("ATM", "Money")
	ui.hide_spin_button()
	ui.show_atm()
	slot_machine.clear_win_lines()
	shop.open_shop()

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
		Global.rounds_taken += 1
		ui.update_spin_count(Global.spins_left)
		slot_machine.emit_signal("spin_started")
		slot_machine.spin()
		UISoundManager.play_click()

		if Global.spins_left == 0:
			current_state = GameState.TRANSITION

func _on_spin_completed(winnings: int):
	Global.coins += winnings
	Global.winnings += winnings
	print("🎰 Spin completed. Added winnings: %d | Total: %d" % [winnings, Global.winnings])
	ui.update_ui(Global.coins, Global.debt, Global.tickets, Global.spins_left)

	if Global.spins_left == 0 and current_state == GameState.TRANSITION:
		await get_tree().create_timer(1.5).timeout
		Global.tickets += 1
		ui.update_ui(Global.coins, Global.debt, Global.tickets, Global.spins_left)
		switch_to_atm()

func _on_deposit_pressed():
	if Global.coins <= 0 or Global.debt <= 0:
		print("⛔ Nothing to deposit.")
		return

	var deposit_amount = int(Global.coins * 0.25)
	deposit_amount = min(deposit_amount, Global.debt)

	Global.coins -= deposit_amount
	Global.debt -= deposit_amount

	UISoundManager.play_click()

	print("💸 Deposited %d coins. Remaining: %d | Debt: %d" % [deposit_amount, Global.coins, Global.debt])

	ui.update_ui(Global.coins, Global.debt, Global.tickets, Global.spins_left)

	if Global.debt <= 0:
		get_tree().change_scene_to_file("res://scenes/NewDayTransition.tscn")

func _on_atm_close_button_pressed():
	if Global.debt <= 0:
		get_tree().change_scene_to_file("res://scenes/NewDayTransition.tscn")
	else:
		ui.get_node("Counters/DayLabel").text = "Day: %d" % Global.current_day
		ui.update_ui(Global.coins, Global.debt, Global.tickets, Global.spins_left)
		switch_to_slot_machine()
		UISoundManager.play_click()

func next_round():
	Global.current_day += 1
	Global.rounds_taken = 0
	Global.winnings = 0
	Global.used_escape_clause = false
	Global.reset_upgrades()
	
	# Calculate daily debt
	Global.debt = calculate_debt_for_day(Global.current_day)

	# 🔄 Update spin price per unit for the day
	var total_spin_cost = int(Global.debt * 0.1)
	Global.spin_price_per_unit = max(1, int(ceil(float(total_spin_cost) / 8)))
	print("🎯 Spin price set for Day %d: %d coins per spin" % [Global.current_day, Global.spin_price_per_unit])

	# 🎁 Apply upgrades
	if "debt_engine" in Global.bought_upgrades:
		var interest_bonus = int(Global.debt * (Global.interest_rate / 100.0) * 0.5)
		Global.coins += interest_bonus
		ui.show_interest_popup(interest_bonus)

	if "compound_suffering" in Global.bought_upgrades and Global.debt > 0:
		Global.interest_rate += 1

	if Global.used_escape_clause:
		Global.used_escape_clause = false
		ui.show_escape_clause_popup()

	# 🎟 Tickets reward scaling by how fast they cleared
	match Global.rounds_taken:
		1: Global.tickets += 7
		2: Global.tickets += 6
		_: Global.tickets += 5

	# 🖥️ Update UI and start day
	var day_label = ui.get_node_or_null("Counters/DayLabel")
	if day_label:
		day_label.text = "Day: %d" % Global.current_day
	ui.update_ui(Global.coins, Global.debt, Global.tickets, Global.spins_left)
	shop.rotate_shop()
	shop.open_shop()
	switch_to_slot_machine()

func game_over():
	if Global.coins <= 0 and Global.debt > 0:
		get_tree().reload_current_scene()
