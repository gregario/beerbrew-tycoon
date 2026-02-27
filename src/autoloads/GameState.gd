extends Node

## GameState — central state machine and runtime state for a BeerBrew Tycoon run.
## This autoload drives the entire game loop.

# ---------------------------------------------------------------------------
# Economy constants
# ---------------------------------------------------------------------------
const STARTING_BALANCE: float = 500.0
const WIN_TARGET: float = 10000.0
const RENT_AMOUNT: float = 150.0
const RENT_INTERVAL: int = 4       # Rent charged every N turns
const MINIMUM_RECIPE_COST: int = 50  # Cheapest base malt (15) + cheapest hop (20) + cheapest yeast (15)

# ---------------------------------------------------------------------------
# State machine
# ---------------------------------------------------------------------------
enum State {
	MARKET_CHECK,    # Show market demand; auto-transitions to STYLE_SELECT
	STYLE_SELECT,    # Player picks a beer style
	RECIPE_DESIGN,   # Player picks malt, hop, yeast
	BREWING_PHASES,  # Player adjusts phase sliders and confirms brew
	RESULTS,         # Show quality score, revenue, balance
	GAME_OVER        # Win or loss end screen
}

signal state_changed(new_state: int)
signal balance_changed(new_balance: float)
signal rent_charged(amount: float, new_balance: float)
signal game_won()
signal game_lost()

# ---------------------------------------------------------------------------
# Runtime state
# ---------------------------------------------------------------------------
var current_state: State = State.MARKET_CHECK
var balance: float = STARTING_BALANCE
var turn_counter: int = 0

var current_style: Resource = null
var current_recipe: Dictionary = {}  # {malts: Array, hops: Array, yeast: Yeast, adjuncts: Array}
var recipe_history: Array = []       # Array of {style_id, malt_ids, hop_ids, yeast_id, adjunct_ids}
var last_brew_result: Dictionary = {}

# Taste skill
var general_taste: int = 0
var style_taste: Dictionary = {}
var discoveries: Dictionary = {}
var temp_control_quality: int = 50

# Run statistics
var total_revenue: float = 0.0
var best_quality: float = 0.0
var is_brewing: bool = false

# Win/loss tracking for game over screen
var run_won: bool = false
var rent_due_this_turn: bool = false

# ---------------------------------------------------------------------------
# State machine
# ---------------------------------------------------------------------------
func advance_state() -> void:
	match current_state:
		State.MARKET_CHECK:
			_set_state(State.STYLE_SELECT)
		State.STYLE_SELECT:
			_set_state(State.RECIPE_DESIGN)
		State.RECIPE_DESIGN:
			_set_state(State.BREWING_PHASES)
		State.BREWING_PHASES:
			_set_state(State.RESULTS)
		State.RESULTS:
			_on_results_continue()
		State.GAME_OVER:
			pass  # Handled by reset() or quit

func _on_results_continue() -> void:
	# Increment turn, rotate demand if scheduled, process rent, check win/loss, advance
	turn_counter += 1
	if MarketSystem.should_rotate(turn_counter):
		MarketSystem.rotate_demand()
	rent_due_this_turn = check_rent_due()
	if rent_due_this_turn:
		deduct_rent()
	if check_win_condition():
		run_won = true
		_set_state(State.GAME_OVER)
		game_won.emit()
	elif check_loss_condition():
		run_won = false
		_set_state(State.GAME_OVER)
		game_lost.emit()
	else:
		_set_state(State.MARKET_CHECK)

func _set_state(new_state: State) -> void:
	current_state = new_state
	state_changed.emit(new_state)

# ---------------------------------------------------------------------------
# Style and recipe setters
# ---------------------------------------------------------------------------
func set_style(style: Resource) -> void:
	current_style = style

func set_recipe(recipe: Dictionary) -> void:
	current_recipe = recipe

# ---------------------------------------------------------------------------
# Economy methods
# ---------------------------------------------------------------------------
static func get_recipe_cost(recipe: Dictionary) -> int:
	var total := 0
	for malt in recipe.get("malts", []):
		total += malt.cost
	for hop in recipe.get("hops", []):
		total += hop.cost
	var yeast: Resource = recipe.get("yeast", null)
	if yeast:
		total += yeast.cost
	for adj in recipe.get("adjuncts", []):
		total += adj.cost
	return total

func deduct_ingredient_cost() -> bool:
	var cost := get_recipe_cost(current_recipe)
	if balance < cost:
		return false
	balance -= cost
	balance_changed.emit(balance)
	return true

func add_revenue(amount: float) -> void:
	balance += amount
	total_revenue += amount
	balance_changed.emit(balance)
	# Win/loss detection happens in _on_results_continue, not here.

func check_win_condition() -> bool:
	return balance >= WIN_TARGET

func check_loss_condition() -> bool:
	return balance <= 0.0 or balance < MINIMUM_RECIPE_COST

## Increment taste after a brew. Called with the style name.
func increment_taste(style_name: String) -> void:
	general_taste += 1
	var current: int = style_taste.get(style_name, 0)
	style_taste[style_name] = current + 1

## Returns the palate level display name.
func get_palate_name() -> String:
	if general_taste <= 1:
		return "Novice"
	elif general_taste <= 3:
		return "Developing"
	elif general_taste <= 5:
		return "Experienced"
	else:
		return "Expert"

func check_rent_due() -> bool:
	return turn_counter > 0 and turn_counter % RENT_INTERVAL == 0

func deduct_rent() -> void:
	balance -= RENT_AMOUNT
	balance_changed.emit(balance)
	rent_charged.emit(RENT_AMOUNT, balance)

# ---------------------------------------------------------------------------
# Brew recording
# ---------------------------------------------------------------------------
func record_brew(quality: float) -> void:
	if quality > best_quality:
		best_quality = quality
	var malt_ids: Array = []
	for m in current_recipe.get("malts", []):
		malt_ids.append(m.ingredient_id)
	malt_ids.sort()
	var hop_ids: Array = []
	for h in current_recipe.get("hops", []):
		hop_ids.append(h.ingredient_id)
	hop_ids.sort()
	var yeast_id: String = current_recipe.get("yeast").ingredient_id if current_recipe.get("yeast") else ""
	var adjunct_ids: Array = []
	for a in current_recipe.get("adjuncts", []):
		adjunct_ids.append(a.ingredient_id)
	adjunct_ids.sort()
	recipe_history.append({
		"style_id": current_style.style_id if current_style else "",
		"malt_ids": malt_ids,
		"hop_ids": hop_ids,
		"yeast_id": yeast_id,
		"adjunct_ids": adjunct_ids,
	})

func set_brewing(active: bool) -> void:
	is_brewing = active

# ---------------------------------------------------------------------------
# Revenue calculation
# ---------------------------------------------------------------------------
## quality_multiplier: maps score 0→0.5x, 50→1.0x, 100→2.0x (linear)
static func quality_to_multiplier(quality_score: float) -> float:
	return lerp(0.5, 2.0, quality_score / 100.0)

func calculate_revenue(quality_score: float) -> float:
	if current_style == null:
		return 0.0
	var style_id: String = current_style.style_id
	var demand_multiplier := MarketSystem.get_demand_weight(style_id)
	var quality_mult := quality_to_multiplier(quality_score)
	return current_style.base_price * quality_mult * demand_multiplier

# ---------------------------------------------------------------------------
# Brew execution — canonical entry point for a complete brew turn
# ---------------------------------------------------------------------------
## Executes the full brew cycle: deduct cost → calculate quality → calculate
## revenue → add revenue → record brew → store result → advance state.
## Returns the result Dictionary (with "final_score" and "revenue" keys),
## or an empty Dictionary if the ingredient cost could not be deducted.
func execute_brew(sliders: Dictionary) -> Dictionary:
	if not deduct_ingredient_cost():
		return {}

	set_brewing(true)

	var result := QualityCalculator.calculate_quality(
		current_style,
		current_recipe,
		sliders,
		recipe_history
	)

	var revenue := calculate_revenue(result["final_score"])
	add_revenue(revenue)
	result["revenue"] = revenue

	record_brew(result["final_score"])

	if current_style:
		increment_taste(current_style.style_name)

	last_brew_result = result

	set_brewing(false)
	advance_state()

	return result

# ---------------------------------------------------------------------------
# Reset (new run)
# ---------------------------------------------------------------------------
func reset() -> void:
	balance = STARTING_BALANCE
	turn_counter = 0
	current_style = null
	current_recipe = {}
	recipe_history = []
	last_brew_result = {}
	total_revenue = 0.0
	best_quality = 0.0
	is_brewing = false
	run_won = false
	rent_due_this_turn = false
	general_taste = 0
	style_taste = {}
	discoveries = {}
	temp_control_quality = 50
	MarketSystem.initialize_demand()
	_set_state(State.MARKET_CHECK)
