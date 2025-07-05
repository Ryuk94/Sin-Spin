extends CanvasLayer

@onready var spins_label := get_node_or_null("Counters/SpinsLeftLabel")
@onready var coins_label := get_node_or_null("Counters/CoinsLabel")
@onready var debt_label := get_node_or_null("Counters/DebtLabel")
@onready var tickets_label := get_node_or_null("Counters/TicketsLabel")
@onready var current_interest_label := get_node_or_null(
	"InterestDisplayContainer/InterestLabelsHBox/CurrentInterestLabel"
)
@onready var total_interest_earned_label := get_node_or_null(
	"InterestDisplayContainer/InterestLabelsHBox/TotalInterestEarnedLabel"
)
@onready var interest_display_container := get_node_or_null("InterestDisplayContainer")
@onready var escape_label := get_node_or_null("EscapeLabel")
@onready var winnings_label := get_node_or_null("/root/MainGame/SpendRoot/ATM/WinningsLabel")
@onready var spin_button := get_node_or_null("/root/MainGame/GameplayRoot/SlotMachine/Spin")
@onready var deposit_button := get_node_or_null("/root/MainGame/SpendRoot/ATM/ATMButtons/Deposit")
@onready var close_button := get_node_or_null("/root/MainGame/SpendRoot/ATM/ATMButtons/Close")


func _ready():
	if deposit_button:
		deposit_button.visible = false
	if close_button:
		close_button.visible = false
	_create_game_over_overlay()  # Create the overlay dynamically


func update_ui(coins: int, debt: int, tickets: int, spins_left: int) -> void:
	if spins_label:
		spins_label.text = "Spins: %d" % spins_left
	if coins_label:
		coins_label.text = "Coins: %d" % coins
	if debt_label:
		debt_label.text = "Debt: %d" % debt
	if tickets_label:
		tickets_label.text = "Tickets: %d" % tickets

	var atm_debt_label := get_node_or_null("/root/MainGame/SpendRoot/ATM/DebtLabel")
	if atm_debt_label:
		atm_debt_label.text = "Debt: %d" % debt

	if winnings_label:
		winnings_label.text = "Winnings: %d" % Global.winnings


func update_spin_count(spins_left: int) -> void:
	if spins_label:
		spins_label.text = "Spins: %d" % spins_left


func update_debt(debt: int) -> void:
	var main_label := get_node_or_null("DebtLabel")
	if main_label:
		main_label.text = "Debt: " + str(debt)

	var atm_label := get_node_or_null("/root/MainGame/SpendRoot/ATM/DebtLabel")
	if atm_label:
		atm_label.text = "Debt: " + str(debt)


func update_spin_cost(value: int) -> void:
	var final_cost = Global.spin_price_per_unit * value


func show_spin_button() -> void:
	if spin_button:
		spin_button.visible = true


func hide_spin_button() -> void:
	if spin_button:
		spin_button.visible = false


func show_atm() -> void:
	hide_spin_button()
	if deposit_button:
		deposit_button.visible = true
	if close_button:
		close_button.visible = true


func hide_atm() -> void:
	if deposit_button:
		deposit_button.visible = false
	if close_button:
		close_button.visible = false


func show_interest_popup(amount: int) -> void:
	if current_interest_label:
		current_interest_label.text = "+%d coins gained from interest" % amount
		current_interest_label.visible = true
		if interest_display_container:
			interest_display_container.visible = true
		await get_tree().create_timer(2).timeout
		current_interest_label.visible = false
		if interest_display_container:
			interest_display_container.visible = false


func update_total_interest_earned(amount: int) -> void:
	if total_interest_earned_label:
		total_interest_earned_label.text = "Total Earned: %d" % amount


func show_escape_clause_popup() -> void:
	if escape_label:
		escape_label.text = "You escaped the day... but lost all upgrades."
		escape_label.visible = true
		await get_tree().create_timer(2).timeout
		escape_label.visible = false


var _game_over_overlay: Control = null


func _create_game_over_overlay():
	_game_over_overlay = Control.new()
	_game_over_overlay.name = "GameOverOverlay"
	_game_over_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_game_over_overlay.visible = false
	add_child(_game_over_overlay)

	var bg = ColorRect.new()
	bg.name = "Background"
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(1, 0, 0, 1)  # Opaque Red background
	_game_over_overlay.add_child(bg)

	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.size = Vector2(600, 400)  # Adjusted size for bigger UI
	vbox.alignment = VBoxContainer.ALIGNMENT_CENTER
	_game_over_overlay.add_child(vbox)

	var label = Label.new()
	label.name = "GameOverLabel"
	label.text = "GAME OVER"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(label)

	var button = Button.new()
	button.name = "RestartButton"
	button.text = "Restart"
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(button)

	# Connect button to MainGame directly from UI.gd
	# Ensure MainGame is available at /root/MainGame
	var main_game_node = get_node_or_null("/root/MainGame")
	print("DEBUG: MainGame node: %s" % main_game_node)  # Debug print
	if main_game_node:
		if button.pressed.is_connected(main_game_node._on_game_over_restart_pressed):
			button.pressed.disconnect(main_game_node._on_game_over_restart_pressed)
		button.pressed.connect(main_game_node._on_game_over_restart_pressed)
	else:
		print("ERROR: MainGame node not found at /root/MainGame for connecting RestartButton.")

	# Explicitly center the VBoxContainer
	vbox.position = (get_viewport().get_visible_rect().size - vbox.size) / 2


func show_game_over_overlay():
	if _game_over_overlay:
		_game_over_overlay.visible = true
		get_tree().paused = true  # Pause the game


func hide_game_over_overlay():
	if _game_over_overlay:
		_game_over_overlay.visible = false
		get_tree().paused = false  # Unpause the game
