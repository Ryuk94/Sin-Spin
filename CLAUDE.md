# CLAUDE.MD – Godot Slot Roguelike Dev Partner

We're co-developing a **polished, modular, bug-free** Godot game. Your role is to **minimize rework**, **prevent bugs before they happen**, and write **efficient, token-light** logic.

---

## 🎰 GAME OVERVIEW

- **2D singleplayer slot machine roguelike**
- No combat. Gameplay is driven by **spins, upgrades, money/debt, and progression.**
- Inspired by **CloverPit**, **Balatro**, and **Buckshot Roulette**
- Core loop: **Spin → Deposit → Shop → New Day**
- Emphasis on **UI clarity**, **clean state transitions**, and **replayable runs**

---

## 🔁 CURRENT SCENE STRUCTURE

Based on the current `MainGame` tree:

```
MainGame
├── Background
├── GameplayRoot
│   ├── Bedroom
│   └── SlotMachine
│       ├── ColorRects / Frame / Reels
│       ├── Spin (Button)
│       └── SpinPurchaseUI
├── SpendRoot
│   ├── ATM
│   └── Shop
└── UI
    ├── EscapeLabel
    ├── Counters
    │   ├── InterestDisplayContainer
    │   │   └── InterestLabelsHBox
    │   │       ├── CurrentInterestLabel
    │   │       └── TotalInterestEarnedLabel
    └── Counters2
        └── InterestLabel
```

All code and scene structure must **respect this layout** unless we plan a refactor.

---

## ✅ WHAT “DONE” MEANS

Your work is complete when:
- ✅ All linter & formatting hooks pass (gdformat, gdlint)
- ✅ All scenes load and function in-editor
- ✅ UI buttons/signals are functional and bug-free
- ✅ Old/broken logic is deleted
- ✅ Logic is explained via comments where needed

---

## 🚨 HOOKS MUST PASS

Hooks enforce:
- ❌ No broken scene references or paths
- ❌ No formatting violations
- ❌ No unused nodes, signals, or variables
- ❌ No leftover debug code

Run these before any claim of "done":
```sh
gdformat . && gdlint . && playtest
```

---

## 🎯 DEVELOPMENT PROCESS

### Always: **Research → Plan → Implement**
Never code without context.

When assigned any task:
> “Let me research the project and create a plan before implementing.”

If unsure on architecture:
> “Let me ultrathink about this structure before proposing a solution.”

Use `@onready`, preload paths, and properly typed variables throughout.

---

## 🧠 SCENE ARCHITECTURE RULES

- Each major gameplay screen (SlotMachine, ATM, Shop) lives under **MainGame**
- Screens are **shown/hidden** or **camera-transitioned** (depending on 2D/3D setup)
- UI lives in its own branch, with signals/data piped from game logic
- Use **signals** and **state enums** to manage transitions, not timers or yield()
- Use **SpinPurchaseUI** to control how many spins are available per round
- Interest and coin counters update via signals, not polling

---

## ❌ FORBIDDEN PATTERNS

- ❌ `yield()` – use `await` or signals
- ❌ Magic strings for node paths – use `@onready`, `get_node_or_null()`
- ❌ `print()` for debugging – use `push_warning()` or debugger breakpoints
- ❌ Direct manipulation of nodes from distant scenes
- ❌ Logic inside UI scripts (display only)
- ❌ Mixed-purpose autoloads – isolate globals vs systems

---

## ✅ REQUIRED PATTERNS

- ✅ `@onready var spin_button := $SlotMachine/Spin`
- ✅ Signals for win, loss, upgrade, transition
- ✅ Early returns in functions
- ✅ Reused PackedScenes via `preload()`
- ✅ Concrete types (`var current_day: int = 1`)
- ✅ One source of truth for interest, coins, debt, etc. (likely `Global.gd`)

---

## 🧪 TESTING STRATEGY

| Feature Type            | How to Test                              |
|-------------------------|-------------------------------------------|
| Slot payout logic       | Unit test in `tests/slot_payout.gd`       |
| UI transitions          | Manual test or `assert(ui.visible)`      |
| Upgrade effects         | Table-driven test or debugger tracing     |
| Daily interest system   | Autoload state assertions                 |
| State transitions       | Enum + scene visibility validation        |

---

## PROJECT STRUCTURE CONVENTION

```
scenes/
  MainGame.tscn
  SlotMachine/
    SlotMachine.tscn
    SpinPurchaseUI.tscn
    Reels/
  SpendRoot/
    ATM.tscn
    Shop.tscn
  UI/
    Counters.tscn
    Labels.tscn

scripts/
  core/
    main_game.gd
    state_manager.gd
  systems/
    spin_logic.gd
    interest_calculator.gd
    upgrade_manager.gd
  ui/
    counters.gd
    labels.gd
  upgrades/
    greed_dividend.gd
    hexs_wink.gd

autoload/
  Global.gd
```

---

## 🤖 MULTI-AGENT WORKFLOWS

When needed:
> “I'll spawn agents to tackle different aspects of this task.”

Example:
- One agent updates the ATM logic
- One handles UI Counter display
- One handles signal connections and test coverage

---

## 🧠 WHEN YOU’RE STUCK

1. **Stop spiraling** – don’t add hacks
2. **Ask**: “A or B?” – I’ll guide you
3. **Ultrathink** for architecture
4. **Simplify** the logic
5. **Use the scene tree** as source of truth

---

## 🧮 PERFORMANCE & CLARITY

- Avoid polling in `_process()` – rely on signals/state
- Use node visibility toggles over delete/add when possible
- Monitor frame rate via `Engine.get_frames_per_second()`
- Pool animations, particles, and bonus effects where needed
- Preload assets, don’t load on `_ready()` unless async

---

## 🤝 COLLABORATION REMINDER

- This is a **feature branch** — refactor freely
- No backwards compatibility
- Clear over clever
- Clean over quick
- Functional over fanciful

---

When in doubt:
**"Keep it clean, keep it synced, keep it scene-safe."**
