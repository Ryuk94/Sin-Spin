extends Node

var coins = 10
var current_day = 1
var debt = 50
var base_debt = 50
var spins_left = 0
var tickets = 2
var growth_factor = 1.694
var winnings: int = 0
var total_interest_earned: int = 0  # New variable to track total interest earned
var adult_mode = true
var luck = 0
var multiplier = 1
var interest_rate = 0.05  # Base 5%
var base_interest_rate := 0.05
var extra_interest_rate := 0.0
var compound_penalty_rounds := 0
var rounds_taken := 0
var bought_upgrades: Array = []
var used_escape_clause: bool = false
var spin_price_per_unit := 1


func apply_upgrade(effect: String):
	print("✨ Applying upgrade: %s" % effect)
	match effect:
		"debt_engine":
			pass  # handled at start of day
		"tithe":
			tickets += 4
			print("🎟️ Hex's Tithe: Gained 4 tickets. Total tickets: %d" % tickets)
		"escape_clause":
			used_escape_clause = true
			print("🚪 Escape Clause: Activated.")
		"infernal_interest":
			interest_rate += 0.05
			print("💰 Infernal Interest: Interest rate increased to %f." % interest_rate)
		"hex_hack":
			pass  # handled passively
		"double_damnation":
			luck = int(luck * 0.5)
			multiplier = max(1, multiplier * 2)  # safety
			print(
				(
					"😈 Double or Damnation: Luck halved to %d, Multiplier doubled to %d."
					% [luck, multiplier]
				)
			)
		"compound_suffering":
			pass  # handled in ATM logic
		"succubus_wink":
			luck += 2
			print("😉 Succubus's Wink: Luck increased by 2. Total luck: %d" % luck)
		"greed_dividend":
			pass  # handled per spin
		"hex_hand":
			pass  # reroll logic in spin


func qualifies_for_escape_clause() -> bool:
	var original_debt = calculate_debt_for_day(current_day)
	return float(original_debt - debt) / float(original_debt) >= 0.7


func reset_upgrades():
	bought_upgrades.clear()
	luck = 0
	multiplier = 1
	interest_rate = base_interest_rate
	extra_interest_rate = 0.0
	compound_penalty_rounds = 0


func calculate_debt_for_day(day: int) -> int:
	return int(base_debt * pow(growth_factor, day - 1))
