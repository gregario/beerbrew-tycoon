# Stage 4A — Contracts Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement a contract system where clients offer brewing jobs with style/quality requirements, rewards, deadlines, and penalties.

**Architecture:** New `ContractManager` autoload manages contract generation, acceptance, fulfillment, and deadline tracking. Contracts are procedural Dictionaries (same pattern as StaffManager staff). GameState hooks: `execute_brew()` checks fulfillment after scoring, `_on_results_continue()` ticks deadlines. ContractBoard is a full-screen overlay UI. BreweryScene gets a "Contracts" button.

**Tech Stack:** Godot 4 / GDScript, GUT testing framework, `make test` runner.

**Key References:**
- Wireframe: `design/wireframes/contracts.md`
- Spec: `openspec/changes/post-mvp-roadmap/specs/contracts/spec.md`
- Stack profile: `stacks/godot/STACK.md` (read before coding)

---

### Task 1: ContractManager Autoload — Data Model and Generation

**Files:**
- Create: `src/autoloads/ContractManager.gd`
- Create: `src/tests/test_contract_manager.gd`
- Modify: `src/project.godot` (add autoload entry)

**Context:** ContractManager owns contract state: available contracts (2-3 offered), active contracts (max 2 accepted), and a refresh counter. Contracts are Dictionaries with: contract_id, client_name, required_style, minimum_quality, reward, bonus_reward, deadline_turns, remaining_turns, reputation_penalty, status ("available"/"active"/"fulfilled"/"failed").

**Step 1: Write the failing test**

```gdscript
# src/tests/test_contract_manager.gd
extends GutTest

func before_each() -> void:
	GameState.reset()
	ContractManager.reset()

# --- Initial state ---
func test_starts_with_available_contracts() -> void:
	assert_gte(ContractManager.available_contracts.size(), 2)
	assert_lte(ContractManager.available_contracts.size(), 3)

func test_starts_with_no_active_contracts() -> void:
	assert_eq(ContractManager.active_contracts.size(), 0)

func test_max_active_contracts_is_2() -> void:
	assert_eq(ContractManager.MAX_ACTIVE, 2)

# --- Contract structure ---
func test_contract_has_required_fields() -> void:
	var contract: Dictionary = ContractManager.available_contracts[0]
	assert_has(contract, "contract_id")
	assert_has(contract, "client_name")
	assert_has(contract, "required_style")
	assert_has(contract, "minimum_quality")
	assert_has(contract, "reward")
	assert_has(contract, "bonus_reward")
	assert_has(contract, "deadline_turns")
	assert_has(contract, "remaining_turns")
	assert_has(contract, "reputation_penalty")

func test_contract_quality_in_valid_range() -> void:
	var contract: Dictionary = ContractManager.available_contracts[0]
	var quality: float = contract.get("minimum_quality", 0.0)
	assert_gte(quality, 30.0)
	assert_lte(quality, 80.0)

func test_contract_reward_positive() -> void:
	var contract: Dictionary = ContractManager.available_contracts[0]
	assert_gt(contract.get("reward", 0), 0)

func test_contract_deadline_positive() -> void:
	var contract: Dictionary = ContractManager.available_contracts[0]
	assert_gt(contract.get("deadline_turns", 0), 0)

# --- Accept ---
func test_accept_moves_to_active() -> void:
	var cid: String = ContractManager.available_contracts[0]["contract_id"]
	var result: bool = ContractManager.accept(cid)
	assert_true(result)
	assert_eq(ContractManager.active_contracts.size(), 1)

func test_accept_removes_from_available() -> void:
	var initial_count: int = ContractManager.available_contracts.size()
	var cid: String = ContractManager.available_contracts[0]["contract_id"]
	ContractManager.accept(cid)
	assert_eq(ContractManager.available_contracts.size(), initial_count - 1)

func test_cannot_accept_more_than_max() -> void:
	# Accept 2
	ContractManager.accept(ContractManager.available_contracts[0]["contract_id"])
	ContractManager.accept(ContractManager.available_contracts[0]["contract_id"])
	# Generate more and try to accept a 3rd
	ContractManager.generate_contracts()
	var result: bool = ContractManager.accept(ContractManager.available_contracts[0]["contract_id"])
	assert_false(result)
	assert_eq(ContractManager.active_contracts.size(), 2)

func test_accept_nonexistent_fails() -> void:
	var result: bool = ContractManager.accept("fake_id")
	assert_false(result)

# --- Generation ---
func test_generate_creates_2_to_3() -> void:
	ContractManager.generate_contracts()
	assert_gte(ContractManager.available_contracts.size(), 2)
	assert_lte(ContractManager.available_contracts.size(), 3)

func test_contracts_use_valid_styles() -> void:
	for contract in ContractManager.available_contracts:
		assert_true(contract["required_style"] in ContractManager.STYLE_IDS,
			"Style %s should be valid" % contract["required_style"])

# --- Refresh counter ---
func test_refresh_interval() -> void:
	assert_eq(ContractManager.REFRESH_INTERVAL, 3)

func test_refresh_counter_starts_at_interval() -> void:
	assert_eq(ContractManager.refresh_counter, ContractManager.REFRESH_INTERVAL)

# --- Persistence ---
func test_save_and_load() -> void:
	ContractManager.accept(ContractManager.available_contracts[0]["contract_id"])
	ContractManager.refresh_counter = 1
	var data: Dictionary = ContractManager.save_state()
	ContractManager.reset()
	assert_eq(ContractManager.active_contracts.size(), 0)
	ContractManager.load_state(data)
	assert_eq(ContractManager.active_contracts.size(), 1)
	assert_eq(ContractManager.refresh_counter, 1)

# --- Signals ---
func test_contract_accepted_signal() -> void:
	watch_signals(ContractManager)
	ContractManager.accept(ContractManager.available_contracts[0]["contract_id"])
	assert_signal_emitted(ContractManager, "contract_accepted")
```

**Step 2: Run test to verify it fails**

Run: `make test`
Expected: FAIL — ContractManager does not exist.

**Step 3: Write the implementation**

```gdscript
# src/autoloads/ContractManager.gd
extends Node

## ContractManager — manages contract generation, acceptance, fulfillment,
## deadline tracking, and rewards/penalties.

const MAX_ACTIVE: int = 2
const REFRESH_INTERVAL: int = 3
const QUALITY_BONUS_THRESHOLD: float = 20.0

const CLIENT_NAMES: Array[String] = [
	"Hofbrau Munich", "Biergarten Co.", "Craft Collective",
	"The Copper Kettle", "Brewmaster's Guild", "Golden Tap",
	"Barrel & Hops", "Prost Pub", "Ales & Tales",
	"The Thirsty Monk", "Suds & Stories", "Hops & Dreams",
]

const STYLE_IDS: Array[String] = [
	"lager", "pale_ale", "stout", "wheat_beer",
]

signal contract_accepted(contract_id: String)
signal contract_fulfilled(contract_id: String, reward: int, bonus: int)
signal contract_failed(contract_id: String, penalty: int)
signal contracts_refreshed()

var available_contracts: Array = []
var active_contracts: Array = []
var refresh_counter: int = REFRESH_INTERVAL
var _next_id: int = 0

# ---------------------------------------------------------------------------
# Generation
# ---------------------------------------------------------------------------
func generate_contracts() -> void:
	available_contracts = []
	var count: int = randi_range(2, 3)
	var used_clients: Array[String] = []
	for c in active_contracts:
		used_clients.append(c.get("client_name", ""))
	var shuffled_clients: Array[String] = CLIENT_NAMES.duplicate()
	shuffled_clients.shuffle()
	for i in range(count):
		var client_name: String = ""
		for name in shuffled_clients:
			if name not in used_clients:
				client_name = name
				used_clients.append(name)
				break
		if client_name == "":
			client_name = "Client %d" % _next_id
		var style_id: String = STYLE_IDS[randi_range(0, STYLE_IDS.size() - 1)]
		var min_quality: float = float(randi_range(30, 80))
		var deadline: int = randi_range(3, 6)
		var base_reward: int = int(min_quality * 4.0) + randi_range(50, 150)
		var bonus_reward: int = int(base_reward * 0.25)
		var penalty: int = int(base_reward * 0.4)
		var contract_id: String = "contract_%d" % _next_id
		_next_id += 1
		available_contracts.append({
			"contract_id": contract_id,
			"client_name": client_name,
			"required_style": style_id,
			"minimum_quality": min_quality,
			"reward": base_reward,
			"bonus_reward": bonus_reward,
			"deadline_turns": deadline,
			"remaining_turns": deadline,
			"reputation_penalty": penalty,
		})

# ---------------------------------------------------------------------------
# Accept
# ---------------------------------------------------------------------------
func accept(contract_id: String) -> bool:
	if active_contracts.size() >= MAX_ACTIVE:
		return false
	var index: int = -1
	for i in range(available_contracts.size()):
		if available_contracts[i].get("contract_id", "") == contract_id:
			index = i
			break
	if index < 0:
		return false
	var contract: Dictionary = available_contracts[index]
	available_contracts.remove_at(index)
	active_contracts.append(contract)
	contract_accepted.emit(contract_id)
	return true

# ---------------------------------------------------------------------------
# Fulfillment check
# ---------------------------------------------------------------------------
func check_fulfillment(brewed_style_id: String, quality: float) -> Dictionary:
	for i in range(active_contracts.size() - 1, -1, -1):
		var contract: Dictionary = active_contracts[i]
		if contract["required_style"] != brewed_style_id:
			continue
		if quality < contract["minimum_quality"]:
			continue
		# Fulfilled!
		active_contracts.remove_at(i)
		var reward: int = contract["reward"]
		var bonus: int = 0
		if quality >= contract["minimum_quality"] + QUALITY_BONUS_THRESHOLD:
			bonus = contract["bonus_reward"]
		var total: int = reward + bonus
		GameState.balance += total
		GameState.balance_changed.emit(GameState.balance)
		contract_fulfilled.emit(contract["contract_id"], reward, bonus)
		return {
			"fulfilled": true,
			"contract": contract,
			"reward": reward,
			"bonus": bonus,
			"total": total,
		}
	return {"fulfilled": false}

# ---------------------------------------------------------------------------
# Deadline tick
# ---------------------------------------------------------------------------
func tick_deadlines() -> Array:
	var expired: Array = []
	for i in range(active_contracts.size() - 1, -1, -1):
		var contract: Dictionary = active_contracts[i]
		var remaining: int = contract.get("remaining_turns", 0) - 1
		contract["remaining_turns"] = remaining
		if remaining <= 0:
			active_contracts.remove_at(i)
			var penalty: int = contract["reputation_penalty"]
			GameState.balance -= penalty
			GameState.balance_changed.emit(GameState.balance)
			contract_failed.emit(contract["contract_id"], penalty)
			expired.append(contract)
	# Tick refresh counter
	refresh_counter -= 1
	if refresh_counter <= 0:
		generate_contracts()
		refresh_counter = REFRESH_INTERVAL
		contracts_refreshed.emit()
	return expired

# ---------------------------------------------------------------------------
# Persistence
# ---------------------------------------------------------------------------
func save_state() -> Dictionary:
	var avail_copy: Array = []
	for c in available_contracts:
		avail_copy.append(c.duplicate())
	var active_copy: Array = []
	for c in active_contracts:
		active_copy.append(c.duplicate())
	return {
		"available_contracts": avail_copy,
		"active_contracts": active_copy,
		"refresh_counter": refresh_counter,
		"_next_id": _next_id,
	}

func load_state(data: Dictionary) -> void:
	available_contracts = []
	for c in data.get("available_contracts", []):
		available_contracts.append(c.duplicate())
	active_contracts = []
	for c in data.get("active_contracts", []):
		active_contracts.append(c.duplicate())
	refresh_counter = data.get("refresh_counter", REFRESH_INTERVAL)
	_next_id = data.get("_next_id", 0)

# ---------------------------------------------------------------------------
# Reset
# ---------------------------------------------------------------------------
func reset() -> void:
	active_contracts = []
	_next_id = 0
	refresh_counter = REFRESH_INTERVAL
	generate_contracts()
```

**Step 4: Register autoload in project.godot**

Add after BreweryExpansion:
```
autoload/ContractManager="*res://autoloads/ContractManager.gd"
```

**Step 5: Run test to verify it passes**

Run: `make test`
Expected: All new tests PASS, all existing tests still PASS.

**Step 6: Commit**

```
feat: add ContractManager autoload with generation and acceptance
```

---

### Task 2: Contract Fulfillment and Rewards

**Files:**
- Modify: `src/tests/test_contract_manager.gd`

**Context:** Test the fulfillment logic: style matching, quality threshold, reward calculation, bonus for exceeding quality by 20+.

**Step 1: Append tests**

```gdscript
# --- Fulfillment ---
func test_fulfillment_matches_style_and_quality() -> void:
	ContractManager.accept(ContractManager.available_contracts[0]["contract_id"])
	var contract: Dictionary = ContractManager.active_contracts[0]
	var style: String = contract["required_style"]
	var min_q: float = contract["minimum_quality"]
	var initial_balance: float = GameState.balance
	var result: Dictionary = ContractManager.check_fulfillment(style, min_q + 5.0)
	assert_true(result["fulfilled"])
	assert_eq(result["reward"], contract["reward"])
	assert_eq(result["bonus"], 0)  # Not 20+ above minimum
	assert_gt(GameState.balance, initial_balance)

func test_fulfillment_with_bonus() -> void:
	ContractManager.accept(ContractManager.available_contracts[0]["contract_id"])
	var contract: Dictionary = ContractManager.active_contracts[0]
	var style: String = contract["required_style"]
	var min_q: float = contract["minimum_quality"]
	var result: Dictionary = ContractManager.check_fulfillment(style, min_q + 25.0)
	assert_true(result["fulfilled"])
	assert_eq(result["bonus"], contract["bonus_reward"])
	assert_eq(result["total"], contract["reward"] + contract["bonus_reward"])

func test_fulfillment_wrong_style_fails() -> void:
	ContractManager.accept(ContractManager.available_contracts[0]["contract_id"])
	var result: Dictionary = ContractManager.check_fulfillment("nonexistent_style", 100.0)
	assert_false(result["fulfilled"])
	assert_eq(ContractManager.active_contracts.size(), 1)

func test_fulfillment_below_quality_fails() -> void:
	ContractManager.accept(ContractManager.available_contracts[0]["contract_id"])
	var contract: Dictionary = ContractManager.active_contracts[0]
	var style: String = contract["required_style"]
	var min_q: float = contract["minimum_quality"]
	var result: Dictionary = ContractManager.check_fulfillment(style, min_q - 5.0)
	assert_false(result["fulfilled"])
	assert_eq(ContractManager.active_contracts.size(), 1)

func test_fulfillment_removes_from_active() -> void:
	ContractManager.accept(ContractManager.available_contracts[0]["contract_id"])
	var contract: Dictionary = ContractManager.active_contracts[0]
	ContractManager.check_fulfillment(contract["required_style"], contract["minimum_quality"] + 5.0)
	assert_eq(ContractManager.active_contracts.size(), 0)

func test_fulfillment_emits_signal() -> void:
	watch_signals(ContractManager)
	ContractManager.accept(ContractManager.available_contracts[0]["contract_id"])
	var contract: Dictionary = ContractManager.active_contracts[0]
	ContractManager.check_fulfillment(contract["required_style"], contract["minimum_quality"] + 5.0)
	assert_signal_emitted(ContractManager, "contract_fulfilled")

func test_no_active_contracts_returns_not_fulfilled() -> void:
	var result: Dictionary = ContractManager.check_fulfillment("lager", 80.0)
	assert_false(result["fulfilled"])
```

**Step 2: Run tests, verify all pass**

**Step 3: Commit**

```
feat: add contract fulfillment tests with reward and bonus logic
```

---

### Task 3: Deadline Expiry and Penalties

**Files:**
- Modify: `src/tests/test_contract_manager.gd`

**Context:** Test deadline ticking: remaining_turns decrement each turn, expired contracts apply penalty, refresh counter generates new contracts.

**Step 1: Append tests**

```gdscript
# --- Deadline and penalties ---
func test_tick_decrements_remaining_turns() -> void:
	ContractManager.accept(ContractManager.available_contracts[0]["contract_id"])
	var initial: int = ContractManager.active_contracts[0]["remaining_turns"]
	ContractManager.tick_deadlines()
	assert_eq(ContractManager.active_contracts[0]["remaining_turns"], initial - 1)

func test_expired_contract_applies_penalty() -> void:
	ContractManager.accept(ContractManager.available_contracts[0]["contract_id"])
	var contract: Dictionary = ContractManager.active_contracts[0]
	var penalty: int = contract["reputation_penalty"]
	contract["remaining_turns"] = 1  # Will expire on next tick
	var initial_balance: float = GameState.balance
	ContractManager.tick_deadlines()
	assert_eq(ContractManager.active_contracts.size(), 0)
	assert_almost_eq(GameState.balance, initial_balance - penalty, 0.01)

func test_expired_contract_emits_signal() -> void:
	watch_signals(ContractManager)
	ContractManager.accept(ContractManager.available_contracts[0]["contract_id"])
	ContractManager.active_contracts[0]["remaining_turns"] = 1
	ContractManager.tick_deadlines()
	assert_signal_emitted(ContractManager, "contract_failed")

func test_refresh_counter_decrements() -> void:
	ContractManager.refresh_counter = 2
	ContractManager.tick_deadlines()
	assert_eq(ContractManager.refresh_counter, 1)

func test_refresh_generates_new_contracts_at_zero() -> void:
	ContractManager.refresh_counter = 1
	ContractManager.tick_deadlines()
	assert_eq(ContractManager.refresh_counter, ContractManager.REFRESH_INTERVAL)
	assert_gte(ContractManager.available_contracts.size(), 2)

func test_refresh_emits_signal() -> void:
	watch_signals(ContractManager)
	ContractManager.refresh_counter = 1
	ContractManager.tick_deadlines()
	assert_signal_emitted(ContractManager, "contracts_refreshed")
```

**Step 2: Run tests, verify all pass**

**Step 3: Commit**

```
feat: add contract deadline expiry and penalty tests
```

---

### Task 4: GameState Integration

**Files:**
- Modify: `src/autoloads/GameState.gd`
- Modify: `src/tests/test_contract_manager.gd`

**Context:** Wire ContractManager into GameState: (1) check fulfillment after brew in `execute_brew()`, (2) tick deadlines in `_on_results_continue()`, (3) reset ContractManager on game reset.

**Step 1: Append integration tests**

```gdscript
# --- GameState integration ---
func test_reset_resets_contract_manager() -> void:
	ContractManager.accept(ContractManager.available_contracts[0]["contract_id"])
	GameState.reset()
	assert_eq(ContractManager.active_contracts.size(), 0)
	assert_gte(ContractManager.available_contracts.size(), 2)
```

**Step 2: Modify GameState.gd**

a) In `execute_brew()`, after recording brew and BreweryExpansion.record_brew() (around line 288), add fulfillment check:
```gdscript
	# Contract fulfillment check
	if is_instance_valid(ContractManager) and current_style != null:
		var fulfillment: Dictionary = ContractManager.check_fulfillment(
			current_style.style_id, result["final_score"]
		)
		result["contract_fulfillment"] = fulfillment
		if fulfillment.get("fulfilled", false) and is_instance_valid(ToastManager):
			var contract: Dictionary = fulfillment["contract"]
			var bonus_text: String = ""
			if fulfillment["bonus"] > 0:
				bonus_text = " (+$%d bonus)" % fulfillment["bonus"]
			ToastManager.show_toast("Contract fulfilled! %s: +$%d%s" % [
				contract["client_name"], fulfillment["total"], bonus_text
			])
```

b) In `_on_results_continue()`, after staff salary processing (around line 97), add deadline ticking:
```gdscript
	# Contract deadline tick
	if is_instance_valid(ContractManager):
		var expired: Array = ContractManager.tick_deadlines()
		for contract in expired:
			if is_instance_valid(ToastManager):
				ToastManager.show_toast("Contract expired! %s: -$%d penalty" % [
					contract["client_name"], contract["reputation_penalty"]
				])
```

c) In `reset()`, add ContractManager reset (after BreweryExpansion):
```gdscript
	if is_instance_valid(ContractManager):
		ContractManager.reset()
```

**Step 3: Run tests, verify all pass**

**Step 4: Commit**

```
feat: integrate ContractManager with GameState brew and turn lifecycle
```

---

### Task 5: ContractBoard UI

**Files:**
- Create: `src/ui/ContractBoard.gd`

**Context:** Full-screen overlay showing available contracts (with Accept buttons) and active contracts (with deadline countdown). Same pattern as StaffScreen/ResearchTree overlays.

See `design/wireframes/contracts.md` section 2 for exact layout specs.

**Step 1: Create ContractBoard.gd**

```gdscript
# src/ui/ContractBoard.gd
extends CanvasLayer

signal closed()

func _ready() -> void:
	visible = false

func show_board() -> void:
	_build_ui()
	visible = true

func _build_ui() -> void:
	for child in get_children():
		child.queue_free()

	# Dim background
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	# Center panel 900x550
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(900, 550)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(190, 85)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#0B1220")
	panel_style.border_color = Color("#8A9BB1")
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(4)
	panel_style.set_content_margin_all(32)
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	# Header
	var header := HBoxContainer.new()
	vbox.add_child(header)
	var title := Label.new()
	title.text = "CONTRACT BOARD"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var count_label := Label.new()
	count_label.text = "Active: %d/%d" % [ContractManager.active_contracts.size(), ContractManager.MAX_ACTIVE]
	count_label.add_theme_font_size_override("font_size", 20)
	count_label.add_theme_color_override("font_color", Color("#8A9BB1"))
	header.add_child(count_label)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(16, 0)
	header.add_child(spacer)
	var close_btn := Button.new()
	close_btn.text = "X"
	close_btn.pressed.connect(_on_close)
	header.add_child(close_btn)

	vbox.add_child(HSeparator.new())

	# Active contracts section
	var active_label := Label.new()
	active_label.text = "ACTIVE CONTRACTS"
	active_label.add_theme_font_size_override("font_size", 20)
	active_label.add_theme_color_override("font_color", Color("#FFC857"))
	vbox.add_child(active_label)

	if ContractManager.active_contracts.size() == 0:
		var none_label := Label.new()
		none_label.text = "(No active contracts)"
		none_label.add_theme_font_size_override("font_size", 16)
		none_label.add_theme_color_override("font_color", Color("#8A9BB1"))
		vbox.add_child(none_label)
	else:
		for contract in ContractManager.active_contracts:
			_add_active_card(vbox, contract)

	vbox.add_child(HSeparator.new())

	# Available contracts section
	var avail_header := HBoxContainer.new()
	vbox.add_child(avail_header)
	var avail_label := Label.new()
	avail_label.text = "AVAILABLE CONTRACTS"
	avail_label.add_theme_font_size_override("font_size", 20)
	avail_label.add_theme_color_override("font_color", Color.WHITE)
	avail_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	avail_header.add_child(avail_label)
	var refresh_label := Label.new()
	refresh_label.text = "Refresh: %d turns" % ContractManager.refresh_counter
	refresh_label.add_theme_font_size_override("font_size", 16)
	refresh_label.add_theme_color_override("font_color", Color("#8A9BB1"))
	avail_header.add_child(refresh_label)

	var cards_row := HBoxContainer.new()
	cards_row.add_theme_constant_override("separation", 16)
	vbox.add_child(cards_row)

	for contract in ContractManager.available_contracts:
		_add_available_card(cards_row, contract)

func _add_active_card(parent: VBoxContainer, contract: Dictionary) -> void:
	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#0B1220")
	style.border_color = Color("#FFC857")
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(12)
	card.add_theme_stylebox_override("panel", style)
	parent.add_child(card)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	card.add_child(vb)

	var row1 := HBoxContainer.new()
	vb.add_child(row1)
	var client := Label.new()
	client.text = "%s — Wants: %s" % [contract["client_name"], contract["required_style"].capitalize()]
	client.add_theme_font_size_override("font_size", 20)
	client.add_theme_color_override("font_color", Color.WHITE)
	row1.add_child(client)

	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 24)
	vb.add_child(row2)
	var quality := Label.new()
	quality.text = "Min Quality: %d" % int(contract["minimum_quality"])
	quality.add_theme_font_size_override("font_size", 16)
	quality.add_theme_color_override("font_color", Color("#8A9BB1"))
	row2.add_child(quality)
	var reward := Label.new()
	reward.text = "Reward: $%d (+$%d bonus)" % [contract["reward"], contract["bonus_reward"]]
	reward.add_theme_font_size_override("font_size", 16)
	reward.add_theme_color_override("font_color", Color("#5EE8A4"))
	row2.add_child(reward)

	var row3 := HBoxContainer.new()
	row3.add_theme_constant_override("separation", 24)
	vb.add_child(row3)
	var remaining: int = contract.get("remaining_turns", 0)
	var deadline := Label.new()
	deadline.text = "Deadline: %d turns remaining" % remaining
	deadline.add_theme_font_size_override("font_size", 16)
	var deadline_color: Color = Color("#FF7B7B") if remaining <= 1 else Color("#FFB347")
	deadline.add_theme_color_override("font_color", deadline_color)
	row3.add_child(deadline)
	var penalty := Label.new()
	penalty.text = "Penalty: -$%d" % contract["reputation_penalty"]
	penalty.add_theme_font_size_override("font_size", 16)
	penalty.add_theme_color_override("font_color", Color("#FF7B7B"))
	row3.add_child(penalty)

func _add_available_card(parent: HBoxContainer, contract: Dictionary) -> void:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(250, 200)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#0B1220")
	style.border_color = Color("#8A9BB1")
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(12)
	card.add_theme_stylebox_override("panel", style)
	parent.add_child(card)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	card.add_child(vb)

	var name_label := Label.new()
	name_label.text = contract["client_name"]
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	vb.add_child(name_label)

	_add_detail(vb, "Style: %s" % contract["required_style"].capitalize(), Color("#FFC857"))
	_add_detail(vb, "Quality: %d+" % int(contract["minimum_quality"]), Color("#8A9BB1"))
	_add_detail(vb, "Reward: $%d" % contract["reward"], Color("#5EE8A4"))
	_add_detail(vb, "Deadline: %d turns" % contract["deadline_turns"], Color("#8A9BB1"))
	_add_detail(vb, "Penalty: -$%d" % contract["reputation_penalty"], Color("#FF7B7B"))

	var accept_btn := Button.new()
	accept_btn.text = "Accept"
	accept_btn.custom_minimum_size = Vector2(100, 36)
	accept_btn.disabled = ContractManager.active_contracts.size() >= ContractManager.MAX_ACTIVE
	var cid: String = contract["contract_id"]
	accept_btn.pressed.connect(func(): _on_accept(cid))
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color("#5AA9FF")
	btn_style.set_corner_radius_all(4)
	btn_style.set_content_margin_all(4)
	accept_btn.add_theme_stylebox_override("normal", btn_style)
	accept_btn.add_theme_color_override("font_color", Color("#0F1724"))
	vb.add_child(accept_btn)

func _add_detail(parent: VBoxContainer, text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)

func _on_accept(contract_id: String) -> void:
	var success: bool = ContractManager.accept(contract_id)
	if success and is_instance_valid(ToastManager):
		for c in ContractManager.active_contracts:
			if c["contract_id"] == contract_id:
				ToastManager.show_toast("Contract accepted: %s — %s" % [c["client_name"], c["required_style"].capitalize()])
				break
	_build_ui()  # Rebuild to reflect changes

func _on_close() -> void:
	visible = false
	closed.emit()
```

**Step 2: Run tests, verify all pass**

**Step 3: Commit**

```
feat: add ContractBoard overlay UI
```

---

### Task 6: BreweryScene Integration and Results Display

**Files:**
- Modify: `src/scenes/BreweryScene.gd`
- Modify: `src/ui/ResultsOverlay.gd`

**Context:** Add "Contracts" button to the brewery hub bottom bar. Add contract fulfillment display in ResultsOverlay.

**Step 1: Modify BreweryScene.gd**

a) Add signal:
```gdscript
signal contracts_requested()
```

b) Add ContractBoard variable:
```gdscript
var _contract_board: CanvasLayer = null
```

c) In `_build_equipment_ui()`, after the Staff button, add a Contracts button:
```gdscript
# Contracts button — same style as Research/Staff
var contracts_btn := Button.new()
# ... (same styling pattern as Staff button, position adjusted rightward)
contracts_btn.text = "Contracts"
# Add active count badge if contracts exist
if is_instance_valid(ContractManager) and ContractManager.active_contracts.size() > 0:
	contracts_btn.text = "Contracts (%d)" % ContractManager.active_contracts.size()
contracts_btn.pressed.connect(func(): contracts_requested.emit())
```

d) Add handler in Game.gd or BreweryScene.gd to open ContractBoard when signal fires.

**Step 2: Modify ResultsOverlay.gd**

In `populate()`, after the existing content, check for contract fulfillment and display:
```gdscript
# Contract fulfillment display
var fulfillment: Dictionary = result.get("contract_fulfillment", {})
if fulfillment.get("fulfilled", false):
	var contract: Dictionary = fulfillment["contract"]
	_add_contract_panel(contract, fulfillment)
```

Add `_add_contract_panel()` method:
```gdscript
func _add_contract_panel(contract: Dictionary, fulfillment: Dictionary) -> void:
	# Green-bordered panel showing client, style, quality, reward
	# Same pattern as _add_failure_panel but with success color
```

**Step 3: Run tests, verify all pass**

**Step 4: Commit**

```
feat: add Contracts button to brewery hub and contract results display
```

---

## Summary

| Task | Description | Tests Added |
|------|-------------|-------------|
| 1 | ContractManager autoload (generation, accept, save/load) | ~15 |
| 2 | Contract fulfillment and rewards | ~7 |
| 3 | Deadline expiry and penalties | ~6 |
| 4 | GameState integration (brew check, deadline tick, reset) | ~1 |
| 5 | ContractBoard overlay UI | 0 (UI) |
| 6 | BreweryScene + ResultsOverlay integration | 0 (UI) |

**Estimated total new tests:** ~29
**Estimated total tests after:** ~336 (307 existing + ~29 new)
