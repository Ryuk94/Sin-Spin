extends Control

const UPGRADE_POOL = [
	"debt_engine",
	"tithe",
	"escape_clause",
	"infernal_interest",
	"hex_hack",
	"double_damnation",
	"compound_suffering",
	"succubus_wink",
	"greed_dividend",
	"hex_hand"
]

const UPGRADE_ICONS = {
	"debt_engine": preload("res://assets/icons/upgrades/debt_engine.png"),
	"tithe": preload("res://assets/icons/upgrades/tithe.png"),
	"escape_clause": preload("res://assets/icons/upgrades/clause.png"),
	"infernal_interest": preload("res://assets/icons/upgrades/interest.png"),
	"hex_hack": preload("res://assets/icons/upgrades/hack.png"),
	"double_damnation": preload("res://assets/icons/upgrades/double.png"),
	"compound_suffering": preload("res://assets/icons/upgrades/compound.png"),
	"succubus_wink": preload("res://assets/icons/upgrades/wink.png"),
	"greed_dividend": preload("res://assets/icons/upgrades/greed.png"),
	"hex_hand": preload("res://assets/icons/upgrades/hand.png")
}

const UPGRADE_DISPLAY_NAMES = {
	"debt_engine": "Infernal Debt Engine",
	"tithe": "Hex’s Tithe",
	"escape_clause": "The Escape Clause",
	"infernal_interest": "Infernal Interest",
	"hex_hack": "Hex’s Hack",
	"double_damnation": "Double or Damnation",
	"compound_suffering": "Compound Suffering",
	"succubus_wink": "Succubus’s Wink",
	"greed_dividend": "Greed Dividend",
	"hex_hand": "Hex’s Hand"
}

const UPGRADE_DESCRIPTIONS = {
	"debt_engine": "Start of day bonus coins = half of previous day's interest.",
	"tithe": "Gain 4 tickets instantly.",
	"escape_clause": "End day early if 70% of debt is paid. Lose all upgrades.",
	"infernal_interest": "+5% interest rate.",
	"hex_hack": "10% chance for an extra spin per round.",
	"double_damnation": "Halve luck, double winnings.",
	"compound_suffering": "+1% interest per round if debt unpaid.",
	"succubus_wink": "+2 Luck.",
	"greed_dividend": "+1 coin per spin per 50 debt.",
	"hex_hand": "Reroll one losing reel each spin."
}

var upgrades: Array = []
var current_index := 0

@onready var ui := get_node("/root/MainGame/UI")
@onready var message_label := $MessageLabel
@onready var item_name_label := $MarginContainer/InfoPanel/ItemNameLabel
@onready var item_description_label := $MarginContainer/InfoPanel/ItemDescriptionLabel
@onready var confirmation_label := $MarginContainer/InfoPanel/ConfirmationLabel
@onready var buy_button := $MarginContainer/InfoPanel/BuyButton
@onready var tickets_label := $MarginContainer/InfoPanel/TicketsLabel
@onready var item_display := $CarouselContainer/ItemDisplay
@onready var left_arrow := $CarouselContainer/LeftArrow
@onready var right_arrow := $CarouselContainer/RightArrow

enum ShopUIState { HIDDEN, ACTIVE, LOCKED }


func _ready():
	if Global.current_day == 1:
		rotate_shop()


func rotate_shop():
	upgrades.clear()
	upgrades = pick_new_upgrades(3)
	current_index = 0
	update_shop_ui()


func pick_new_upgrades(count: int) -> Array:
	var pool = UPGRADE_POOL.duplicate()
	pool.shuffle()
	return pool.slice(0, count)


func open_shop():
	if upgrades.is_empty():
		set_ui_state(ShopUIState.LOCKED)
	else:
		set_ui_state(ShopUIState.ACTIVE)
		update_shop_ui()


func set_ui_state(state: ShopUIState):
	match state:
		ShopUIState.HIDDEN:
			visible = false
			message_label.text = ""
		ShopUIState.LOCKED:
			visible = true
			message_label.text = "You must pay off your debt to browse the wares."
			$MarginContainer.visible = false
			$CarouselContainer.visible = false
		ShopUIState.ACTIVE:
			visible = true
			message_label.text = ""
			$MarginContainer.visible = true
			$CarouselContainer.visible = true


func open_atm():
	visible = true


func update_shop_ui():
	if upgrades.is_empty():
		item_name_label.text = ""
		item_description_label.text = ""
		tickets_label.text = ""
		confirmation_label.text = ""
		buy_button.disabled = true
		item_display.texture = null
		return

	var current_upgrade = upgrades[current_index]
	item_name_label.text = upgrade_name_to_display(current_upgrade)
	item_description_label.text = get_upgrade_description(current_upgrade)
	tickets_label.text = "Cost: 2 Tickets"
	confirmation_label.text = ""
	buy_button.disabled = false

	item_display.texture = UPGRADE_ICONS.get(current_upgrade, null)
	left_arrow.disabled = upgrades.size() <= 1
	right_arrow.disabled = upgrades.size() <= 1


func show_next():
	if upgrades.size() > 1:
		current_index = (current_index + 1) % upgrades.size()
		update_shop_ui()
		UISoundManager.play_click()


func show_previous():
	if upgrades.size() > 1:
		current_index = (current_index - 1 + upgrades.size()) % upgrades.size()
		update_shop_ui()
		UISoundManager.play_click()


func purchase_current():
	var current_upgrade = upgrades[current_index]
	var cost = 2
	UISoundManager.play_click()

	if Global.tickets >= cost:
		Global.tickets -= cost
		Global.bought_upgrades.append(current_upgrade)
		Global.apply_upgrade(current_upgrade)  # Apply the upgrade effect
		confirmation_label.text = "Purchased!"
		upgrades.remove_at(current_index)

		if upgrades.is_empty():
			message_label.text = "Sold out, you gluttonous thing."
			set_ui_state(ShopUIState.LOCKED)
		else:
			current_index = current_index % upgrades.size()
			update_shop_ui()

		ui.update_ui(Global.coins, Global.debt, Global.tickets, Global.spins_left)
	else:
		confirmation_label.text = "Not enough tickets."


func upgrade_name_to_display(upgrade: String) -> String:
	return UPGRADE_DISPLAY_NAMES.get(upgrade, upgrade.capitalize())


func get_upgrade_description(upgrade: String) -> String:
	return UPGRADE_DESCRIPTIONS.get(upgrade, "Temptation beyond words…")
