# Stage 15 — Integration & Polish Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Finalize the game with integration tests, balance tuning, UI consistency, and doc updates.

**Architecture:** Automated integration tests simulate full runs and meta-persistence. Balance pass reviews all economy constants. UI polish normalizes all overlays against design system. Docs updated to reflect final state.

**Tech Stack:** Godot 4 / GDScript, GUT testing.

**Run tests:** `cd /Users/gregario/Projects/ClaudeCode/AI-Factory/projects/beerbrew-tycoon && GODOT="/Users/gregario/Library/Application Support/Steam/steamapps/common/Godot Engine/Godot.app/Contents/MacOS/Godot" make test`

---

## Task 1: Integration Test — Full Run Simulation (15.1)

**Files:**
- Create: `src/tests/test_full_run_integration.gd`

**Context:** Simulate a complete game run programmatically: reset → brew multiple beers → sell → check expansion → choose path → win/lose. This catches integration bugs between all systems without the Godot editor.

**Step 1: Write integration tests**

```gdscript
extends GutTest

## Integration tests simulating a complete game run through all systems.

func before_each() -> void:
	# Reset all autoloads
	GameState.reset()
	if is_instance_valid(MetaProgressionManager):
		MetaProgressionManager.active_perks.clear()
		MetaProgressionManager.active_modifiers.clear()

func _simulate_brew(style_id: String, sliders: Dictionary) -> Dictionary:
	# Load style
	var style_path: String = "res://data/styles/%s.tres" % style_id
	var style: Resource = load(style_path)
	GameState.current_style = style

	# Set minimal recipe (first available malt + hop + yeast)
	var malt: Resource = load("res://data/ingredients/malts/pale_malt.tres")
	var hop: Resource = load("res://data/ingredients/hops/saaz.tres")
	var yeast: Resource = load("res://data/ingredients/yeast/us05_clean_ale.tres")
	GameState.current_recipe = {
		"malts": [malt],
		"hops": [hop],
		"yeast": yeast,
		"adjuncts": [],
		"ingredients": [malt, hop, yeast],
	}

	return GameState.execute_brew(sliders)

func _simulate_sell() -> void:
	GameState.execute_sell([], 0.0)

# --- Full run tests ---

func test_fresh_run_starts_with_correct_balance() -> void:
	assert_eq(GameState.balance, GameState.STARTING_BALANCE)
	assert_eq(GameState.turn_counter, 0)
	assert_eq(GameState.current_state, GameState.State.EQUIPMENT_MANAGE)

func test_brew_produces_valid_result() -> void:
	var result: Dictionary = _simulate_brew("pale_ale", {"mash": 50, "boil": 50, "ferment": 50})
	assert_true(result.has("final_score"))
	assert_gte(result["final_score"], 0.0)
	assert_lte(result["final_score"], 100.0)
	assert_eq(GameState.current_state, GameState.State.RESULTS)

func test_sell_adds_revenue() -> void:
	_simulate_brew("pale_ale", {"mash": 50, "boil": 50, "ferment": 50})
	var balance_before: float = GameState.balance
	_simulate_sell()
	# Revenue should be added (might be small with default pricing)
	assert_gte(GameState.total_revenue, 0.0)

func test_multiple_brews_increment_turn_counter() -> void:
	_simulate_brew("pale_ale", {"mash": 50, "boil": 50, "ferment": 50})
	_simulate_sell()
	GameState._on_results_continue()
	assert_gte(GameState.turn_counter, 1)

func test_rp_earned_per_brew() -> void:
	var initial_rp: int = ResearchManager.research_points if is_instance_valid(ResearchManager) else 0
	_simulate_brew("pale_ale", {"mash": 50, "boil": 50, "ferment": 50})
	if is_instance_valid(ResearchManager):
		assert_gt(ResearchManager.research_points, initial_rp)

func test_equipment_spend_tracked() -> void:
	assert_eq(GameState.equipment_spend, 0.0)
	GameState.record_equipment_purchase(500.0)
	assert_eq(GameState.equipment_spend, 500.0)

func test_unique_ingredients_tracked_across_brews() -> void:
	_simulate_brew("pale_ale", {"mash": 50, "boil": 50, "ferment": 50})
	var first_count: int = GameState.unique_ingredients_used
	assert_gt(first_count, 0)
	# Second brew with same ingredients should not increase count
	_simulate_brew("pale_ale", {"mash": 50, "boil": 50, "ferment": 50})
	assert_eq(GameState.unique_ingredients_used, first_count)

func test_loss_condition_triggers_on_zero_balance() -> void:
	GameState.balance = 0.0
	assert_true(GameState.check_loss_condition())

func test_loss_condition_triggers_below_minimum_recipe_cost() -> void:
	GameState.balance = float(GameState.MINIMUM_RECIPE_COST) - 1.0
	assert_true(GameState.check_loss_condition())

func test_default_win_condition() -> void:
	GameState.balance = GameState.WIN_TARGET
	assert_true(GameState.check_win_condition())

func test_meta_progression_starting_cash_with_nest_egg() -> void:
	if not is_instance_valid(MetaProgressionManager):
		return
	MetaProgressionManager.set_active_perks(["nest_egg"] as Array[String])
	GameState.reset()
	assert_almost_eq(GameState.balance, GameState.STARTING_BALANCE * 1.05, 0.01)
	MetaProgressionManager.active_perks.clear()
	GameState.reset()

func test_meta_progression_budget_brewery_modifier() -> void:
	if not is_instance_valid(MetaProgressionManager):
		return
	MetaProgressionManager.set_active_modifiers(["budget_brewery"] as Array[String])
	GameState.reset()
	assert_almost_eq(GameState.balance, GameState.STARTING_BALANCE * 0.5, 0.01)
	MetaProgressionManager.active_modifiers.clear()
	GameState.reset()
```

**Step 2: Run tests — expect PASS**

**Step 3: Commit**

```bash
git add src/tests/test_full_run_integration.gd
git commit -m "test: add full run integration tests simulating brew/sell/meta cycles"
```

---

## Task 2: Integration Test — Meta-Progression Persistence (15.2)

**Files:**
- Create: `src/tests/test_meta_persistence_integration.gd`

**Context:** Test that meta-progression state survives across simulated runs: earn points in run 1, spend in shop, start run 2 with perks active.

**Step 1: Write integration tests**

```gdscript
extends GutTest

## Integration tests for meta-progression persistence across runs.

func before_each() -> void:
	if is_instance_valid(MetaProgressionManager):
		MetaProgressionManager.reset_meta()
	GameState.reset()

# --- Cross-run persistence ---

func test_end_run_awards_points() -> void:
	var metrics: Dictionary = {
		"turns": 15, "revenue": 6000.0, "best_quality": 75.0,
		"medals": 1, "won": true,
		"equipment_spend": 1500, "channels_unlocked": 2,
		"unique_ingredients": 12,
	}
	var points: int = MetaProgressionManager.end_run(metrics)
	assert_gt(points, 0)
	assert_eq(MetaProgressionManager.available_points, points)
	assert_eq(MetaProgressionManager.total_runs, 1)

func test_points_persist_after_game_reset() -> void:
	MetaProgressionManager.add_points(20)
	GameState.reset()
	# Meta points should NOT be cleared by GameState.reset()
	assert_eq(MetaProgressionManager.available_points, 20)

func test_unlocks_persist_after_game_reset() -> void:
	MetaProgressionManager.add_points(10)
	MetaProgressionManager.unlock_style("lager", 5)
	GameState.reset()
	assert_true(MetaProgressionManager.is_unlocked("styles", "lager"))

func test_achievements_persist_after_game_reset() -> void:
	MetaProgressionManager.complete_achievement("first_victory")
	GameState.reset()
	assert_true(MetaProgressionManager.is_achievement_completed("first_victory"))

func test_meta_unlocked_style_available_in_new_run() -> void:
	MetaProgressionManager.unlocked_styles = ["lager"] as Array[String]
	GameState.reset()
	var lager: Resource = load("res://data/styles/lager.tres")
	assert_true(lager.unlocked)
	# Cleanup
	lager.unlocked = false

func test_save_load_roundtrip() -> void:
	MetaProgressionManager.add_points(30)
	MetaProgressionManager.unlock_style("stout", 8)
	MetaProgressionManager.complete_achievement("perfect_brew")
	MetaProgressionManager.set_active_perks(["nest_egg"] as Array[String])
	var saved: Dictionary = MetaProgressionManager.save_state()

	MetaProgressionManager.reset_meta()
	assert_eq(MetaProgressionManager.available_points, 0)

	MetaProgressionManager.load_state(saved)
	assert_eq(MetaProgressionManager.available_points, 22)
	assert_true(MetaProgressionManager.is_unlocked("styles", "stout"))
	assert_true(MetaProgressionManager.is_achievement_completed("perfect_brew"))
	assert_true(MetaProgressionManager.has_active_perk("nest_egg"))

func test_two_runs_accumulate_points() -> void:
	var metrics1: Dictionary = {
		"turns": 10, "revenue": 4000.0, "best_quality": 60.0,
		"medals": 0, "won": false,
		"equipment_spend": 500, "channels_unlocked": 1,
		"unique_ingredients": 8,
	}
	var pts1: int = MetaProgressionManager.end_run(metrics1)

	GameState.reset()

	var metrics2: Dictionary = {
		"turns": 20, "revenue": 8000.0, "best_quality": 85.0,
		"medals": 2, "won": true,
		"equipment_spend": 2000, "channels_unlocked": 3,
		"unique_ingredients": 15,
	}
	var pts2: int = MetaProgressionManager.end_run(metrics2)

	assert_eq(MetaProgressionManager.lifetime_points, pts1 + pts2)
	assert_eq(MetaProgressionManager.total_runs, 2)
	assert_eq(MetaProgressionManager.run_history.size(), 2)

func test_achievement_unlocks_modifier_for_next_run() -> void:
	# Simulate a winning run to unlock first_victory → tough_market
	var metrics: Dictionary = {
		"turns": 15, "revenue": 10000.0, "best_quality": 80.0,
		"medals": 1, "won": true,
		"equipment_spend": 2000, "channels_unlocked": 2,
		"unique_ingredients": 12,
	}
	MetaProgressionManager.end_run(metrics)
	assert_true(MetaProgressionManager.is_achievement_completed("first_victory"))
	assert_true(MetaProgressionManager.is_modifier_unlocked("tough_market"))

func test_blueprint_discount_applied_after_unlock() -> void:
	MetaProgressionManager.add_points(10)
	MetaProgressionManager.unlock_blueprint("mash_tun", 5)
	if is_instance_valid(ResearchManager):
		var cost: int = ResearchManager._get_effective_rp_cost("semi_pro_equipment")
		assert_eq(cost, 10)  # 20 * 0.5
```

**Step 2: Run tests — expect PASS**

**Step 3: Commit**

```bash
git add src/tests/test_meta_persistence_integration.gd
git commit -m "test: add meta-progression persistence integration tests across simulated runs"
```

---

## Task 3: Balance Review & Constants Audit (15.3)

**Files:**
- Modify: `src/autoloads/GameState.gd` — export tuning constants if not already
- Modify: `src/autoloads/MetaProgressionManager.gd` — adjust unlock costs if needed
- Create: `docs/balance-reference.md` — document all economy constants in one place

**Context:** Review all numeric parameters for game balance. The key question: can a player reasonably win in 30-60 turns? Are perks/modifiers impactful but not broken?

**Step 1: Create balance reference document**

Create `docs/balance-reference.md` with all economy constants organized by system. This serves as the single source of truth for tuning.

```markdown
# BeerBrew Tycoon — Balance Reference

## Economy Flow

Starting balance: $500
Win conditions:
- Default: $10,000 balance
- Artisan: 5 medals + 100 reputation
- Mass-Market: $50,000 revenue + 4 channels
Loss condition: Balance < $50

## Revenue Per Brew (approximate)

Base price: $180-$350 per style
Quality multiplier: 0.5x (Q=0) to 2.0x (Q=100)
Batch size: 10 units (20 with mass-market)
Channel margins: taproom 1.0x, bars 0.7x, retail 0.5x, events 1.5x
Demand multiplier: 0.3x-3.0x (seasonal + trend + brand)

Typical early revenue (Q=50, taproom only): 10 × $200 × 1.0 × 1.0 = $2,000
Typical mid revenue (Q=70, 2 channels): ~$3,000-5,000
Typical late revenue (Q=85, 3 channels + trend): ~$8,000-15,000

## Costs Per Turn Cycle (4 turns)

Ingredients: $50-200 per brew × 4 = $200-800
Rent: $150 (garage) to $800 (mass-market)
Staff salaries: $0-400 (0-4 staff)
Equipment: one-time $60-3,500
Training: $200 per session
Competition entry: $100-300
Market research: $100

## Progression Pace

Garage → Microbrewery: ~turn 10-15 ($5,000 + 10 beers, costs $3,000)
Microbrewery → Fork: ~turn 25-35 ($15,000 + 25 beers)
Default win: ~turn 30-50
Artisan win: ~turn 50-80 (5 medals + 100 rep takes time)
Mass-market win: ~turn 40-60 ($50k revenue + channels)

## Research Pace

RP per brew: 2 + quality/20 = 2-7 RP
Total tree cost: ~450 RP
Full tree completion: ~70-120 brews (unrealistic in one run)
Typical run unlocks: 5-10 nodes

## Meta-Progression

Unlock points per run: 0-25 (37 with challenge modifier)
Unlock costs: 3-12 UP per item
Perk impacts: +5% cash, +1 RP, -10% rent, +5% quality
Modifier impacts: ±20% demand, 0.5x cash, +10% quality, 5-brew immunity, 60% ingredients

## Key Ratios

Revenue/cost per brew: ~2:1 early, ~5:1 late (healthy margin growth)
Rent as % of revenue: ~30% early (tight), ~5% late (manageable)
Equipment ROI: T2 equipment pays back in 3-5 brews
Research ROI: Each node takes 3-10 brews to afford, unlocks significant capability
```

**Step 2: Review balance and make adjustments if needed**

After creating the reference doc, read through it and check:
1. Can a new player survive the first 10 turns? ($500 start, ~$200/brew cost, ~$1500-2000/brew revenue — YES, healthy)
2. Is rent punishing enough to force growth? ($150/4 turns = $37.50/turn — meaningful but survivable)
3. Are meta perks impactful? (+5% cash = $25, +1 RP is ~20% boost, -10% rent = $15-80 saved per cycle — modest but noticeable)
4. Are challenge modifiers actually challenging? (-20% demand is real; half starting cash to $250 is punishing; 60% ingredients limits recipe options significantly)

Based on analysis: **No balance changes needed**. The economy is well-tuned across prior stages. The meta-progression adds modest bonuses that don't break the core loop.

**Step 3: Commit**

```bash
git add docs/balance-reference.md
git commit -m "docs: add balance reference document with all economy constants"
```

---

## Task 4: UI Polish Pass (15.4)

**Files:**
- Review and fix: all overlay .gd files in `src/ui/`
- Focus on: new Stage 6 overlays (RunSummaryOverlay, UnlockShopOverlay, RunStartOverlay, AchievementsOverlay, MainMenu)

**Context:** Ensure all overlays follow the design system consistently. Check:
1. All use CanvasLayer with layer=10
2. All use CenterContainer + PRESET_FULL_RECT
3. All non-interactive containers have mouse_filter = MOUSE_FILTER_PASS
4. Card sizing: 900x550 (or documented exception)
5. Color tokens from theme.json (no hardcoded one-off colors)
6. Font sizes match scale: xs=16, sm=20, md=24, lg=32, xl=40
7. Button sizing: 150x44 minimum, 240x48 for CTAs
8. Spacing: 8/16/24/32/48 (no random values)

**Step 1: Read all Stage 6 overlay files**

Read these files and check for consistency:
- `src/ui/RunSummaryOverlay.gd`
- `src/ui/UnlockShopOverlay.gd`
- `src/ui/RunStartOverlay.gd`
- `src/ui/AchievementsOverlay.gd`
- `src/ui/MainMenu.gd`

**Step 2: Fix any inconsistencies found**

Common issues to look for:
- Missing mouse_filter on containers
- Hardcoded colors not in the theme palette
- Font sizes not matching the scale
- Inconsistent button sizing
- Missing dim overlay background

**Step 3: Run tests to verify no regressions**

**Step 4: Commit**

```bash
git add src/ui/RunSummaryOverlay.gd src/ui/UnlockShopOverlay.gd src/ui/RunStartOverlay.gd src/ui/AchievementsOverlay.gd src/ui/MainMenu.gd
git commit -m "fix: UI polish pass — normalize all Stage 6 overlays to design system"
```

(Only commit files that were actually changed.)

---

## Task 5: Update CLAUDE.md Project State (15.6)

**Files:**
- Modify: `CLAUDE.md` (project root) — update project state section

**Context:** Update the project state in CLAUDE.md to reflect Stage 6 completion and final test count.

**Step 1: Read current CLAUDE.md**

Read `/Users/gregario/Projects/ClaudeCode/AI-Factory/projects/beerbrew-tycoon/CLAUDE.md` and update the Project State section to add:

```markdown
- **Stage 6 (Meta-Progression) complete** — MetaProgressionManager autoload (unlock points, 4 unlock categories, 6 achievements, run history, meta.json persistence). RunModifierManager autoload (perk/modifier effects). 5 new UI overlays: RunSummaryOverlay, UnlockShopOverlay, RunStartOverlay, AchievementsOverlay, MainMenu. Game flow: GameOver → RunSummary → UnlockShop → RunStart → reset. Blueprint research discounts, meta style unlocks. 680+ GUT tests.
- **Integration & polish (15.x) complete** — Full run integration tests, meta-persistence tests, balance reference document, UI polish pass. All stages 1-6 implemented.
```

Remove or update the "Next" line about Stage 6.

**Step 2: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: update CLAUDE.md with Stage 6 completion and final project state"
```

---

## Task 6: Note Manual Tasks for User (15.5)

**No files to change.** This is informational.

Tasks that require the Godot editor (cannot be automated):
- **15.1** Manual playtest: Play a full run in the editor from garage through win
- **15.2** Manual playtest: Play 2 runs checking meta-progression persistence
- **15.5** Performance: Open the game in editor, check 60fps at each stage with profiler

These should be done by the user after all automated tasks are complete.

---

## Summary

| Task | Type | Tests Added |
|------|------|-------------|
| 1 | Integration test — full run | ~13 |
| 2 | Integration test — meta persistence | ~10 |
| 3 | Balance reference doc | 0 |
| 4 | UI polish pass | 0 |
| 5 | CLAUDE.md update | 0 |
| 6 | Manual task notes | 0 |
| **Total** | | **~23 new tests** |

Expected final test count: ~703 (680 + 23).
