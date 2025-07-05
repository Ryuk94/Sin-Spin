# Game Flow Documentation

This document outlines the key event sequences and transitions within the game.

## New Day Transition Flow

This sequence describes how the game transitions from one day to the next, ensuring UI elements appear in the correct order.

1.  **Player Pays Off Debt:**
	*   Triggered when the player successfully pays off all their debt in the ATM.
	*   In `MainGame.gd`, the `_on_deposit_pressed()` function detects `Global.debt <= 0`.

2.  **Switch to New Day Transition Scene:**
	*   Instead of a full scene change, the `NewDayTransition.tscn` scene is instantiated and added as a child to the current scene's root.
	*   The `MainGame` scene remains loaded in the background.
	*   A signal (`transition_finished`) from `NewDayTransition` is connected to `MainGame` to notify when the transition is complete.

3.  **Player Clicks to Continue (New Day Transition):**
	*   The `NewDayTransition` scene displays the "Day X" message.
	*   The player interacts (e.g., clicks the screen) to proceed.
	*   In `scenes/NewDayTransition.gd`, the `_on_continue_button_pressed()` function is triggered.
	*   This function emits the `transition_finished` signal and then `queue_free()`s the `NewDayTransition` scene, removing it from the tree.

4.  **Return to MainGame and Finalize New Day Setup:**
	*   Upon receiving the `transition_finished` signal, the `_on_new_day_transition_finished()` function in `MainGame.gd` is executed.
	*   This function first calls `_advance_game_day_logic()` to update all global game state variables for the new day (e.g., incrementing day, calculating new debt, resetting upgrades).
	*   After the game state is updated, the UI elements are refreshed and made visible:
		*   `ui.update_ui(...)` to refresh all counter labels.
		*   `shop.rotate_shop()` and `shop.open_shop()` to set up the shop for the new day.
		*   `switch_to_slot_machine()` to bring the slot machine into view.
		*   `slot_machine.set_ui_state(SlotMachine.SlotUIState.PURCHASE)` to display the "Buy Spins" UI, allowing the player to start the new day's gameplay.

## Other Key Game Loops/Events:

*   **Spin Cycle:**
	*   Player buys spins.
	*   Player clicks "SPIN" button (`_on_spin_button_pressed` in `MainGame.gd`).
	*   Slot machine spins (`slot_machine.spin()`).
	*   Spin completes (`_on_spin_completed` signal from `SlotMachine.gd` to `MainGame.gd`).
	*   Winnings are added, UI updated.
	*   If spins run out, transition to ATM.

*   **ATM Interaction:**
	*   Player enters ATM (`switch_to_atm()` in `MainGame.gd`).
	*   Player deposits coins (`_on_deposit_pressed()` in `MainGame.gd`).
	*   Player closes ATM (`_on_atm_close_button_pressed()` in `MainGame.gd`).
	*   If debt is paid, triggers New Day Transition. If not, returns to slot machine.

*   **Shop Interaction:**
	*   Shop is opened (`shop.open_shop()`).
	*   Player browses items (`shop.show_next()`, `shop.show_previous()`).
	*   Player purchases item (`shop.purchase_current()`).
