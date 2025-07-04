extends CanvasLayer

@onready var spins_label := get_node_or_null("Counters/SpinsLeftLabel")
@onready var coins_label := get_node_or_null("Counters/CoinsLabel")
@onready var debt_label := get_node_or_null("Counters/DebtLabel")
@onready var tickets_label := get_node_or_null("Counters/TicketsLabel")
@onready var interest_label := get_node_or_null("Counters/InterestLabel")
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

func update_ui(coins: int, debt: int, tickets: int, spins_left: int) -> void:
	if spins_label: spins_label.text = "Spins: %d" % spins_left
	if coins_label: coins_label.text = "Coins: %d" % coins
	if debt_label: debt_label.text = "Debt: %d" % debt
	if tickets_label: tickets_label.text = "Tickets: %d" % tickets

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
	if interest_label:
		interest_label.text = "+%d coins gained from interest" % amount
		interest_label.visible = true
		await get_tree().create_timer(2).timeout
		interest_label.visible = false

func show_escape_clause_popup() -> void:
	if escape_label:
		escape_label.text = "You escaped the day... but lost all upgrades."
		escape_label.visible = true
		await get_tree().create_timer(2).timeout
		escape_label.visible = false
