extends Node

## GameState — central state machine and runtime state for a BeerBrew Tycoon run.
## This autoload drives the entire game loop.

# ---------------------------------------------------------------------------
# Economy constants
# ---------------------------------------------------------------------------
const STARTING_BALANCE: float = 500.0
const WIN_TARGET: float = 10000.0
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
	SELL,            # Player allocates units to channels and sets pricing
	EQUIPMENT_MANAGE, # Player manages equipment between brews
	RESEARCH_MANAGE, # Player manages research tree between brews
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
var sanitation_quality: int = 50

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
			_set_state(State.SELL)
		State.SELL:
			_on_results_continue()
		State.EQUIPMENT_MANAGE:
			_set_state(State.MARKET_CHECK)
		State.GAME_OVER:
			pass  # Handled by reset() or quit

func _on_results_continue() -> void:
	# Increment turn, tick market (season/trend/saturation), process rent, check win/loss, advance
	turn_counter += 1
	if is_instance_valid(MarketManager):
		MarketManager.tick()
	rent_due_this_turn = check_rent_due()
	if rent_due_this_turn:
		deduct_rent()
	# Staff salary deduction and training tick
	if is_instance_valid(StaffManager):
		StaffManager.tick_training()
		var total_salary: float = StaffManager.deduct_salaries()
		if total_salary > 0.0 and is_instance_valid(ToastManager):
			ToastManager.show_toast("Salaries paid: -$%d (%d staff)" % [int(total_salary), StaffManager.staff_roster.size()])
		StaffManager.refresh_candidates()
	# Contract deadline tick (Stage 4A)
	if is_instance_valid(ContractManager):
		var expired: Array = ContractManager.tick_deadlines()
		for contract in expired:
			if is_instance_valid(ToastManager):
				ToastManager.show_toast("Contract expired! %s: -$%d penalty" % [
					contract["client_name"], contract["reputation_penalty"]
				])
	# Competition tick (Stage 4B)
	if is_instance_valid(CompetitionManager):
		var comp_result: Dictionary = CompetitionManager.tick()
		if comp_result.has("placement"):
			var placement: String = comp_result["placement"]
			var comp_name: String = comp_result.get("competition", {}).get("name", "")
			if placement == "gold" or placement == "silver" or placement == "bronze":
				if is_instance_valid(ToastManager):
					var medal_labels: Dictionary = {"gold": "GOLD MEDAL", "silver": "Silver Medal", "bronze": "Bronze Medal"}
					ToastManager.show_toast("%s! %s — +$%d" % [
						medal_labels[placement], comp_name, comp_result["prize"]
					])
					if comp_result.get("rare_unlock", "") != "":
						ToastManager.show_toast("Gold medal bonus! Unlocked: %s" % comp_result["rare_unlock"])
			elif placement == "none" and comp_result.get("player_quality", 0.0) > 0.0:
				if is_instance_valid(ToastManager):
					ToastManager.show_toast("Competition ended. Your entry didn't place.")
			# Reputation for medals (Stage 5A — artisan path)
			if is_instance_valid(PathManager) and PathManager.has_chosen_path():
				var rep_gain: int = 0
				match placement:
					"gold":
						rep_gain = 5
					"silver":
						rep_gain = 3
					"bronze":
						rep_gain = 1
				if rep_gain > 0:
					PathManager.add_reputation(rep_gain)
					if is_instance_valid(ToastManager):
						ToastManager.show_toast("Reputation +%d (now %d)" % [rep_gain, PathManager.get_reputation()])
	# Specialty beer aging tick (Stage 5B)
	if is_instance_valid(SpecialtyBeerManager):
		SpecialtyBeerManager.tick_aging()
		var completed_aged: Array = SpecialtyBeerManager.get_completed_beers()
		if completed_aged.size() > 0:
			last_brew_result["completed_aged_beers"] = completed_aged
			for aged_beer in completed_aged:
				var aged_quality: float = aged_beer.get("final_quality", 50.0)
				var aged_revenue: float = aged_quality * 2.0  # Premium pricing for aged beers
				add_revenue(aged_revenue)
				if is_instance_valid(ToastManager):
					ToastManager.show_toast("Aged %s ready! Quality: %d — Revenue: +$%d" % [
						aged_beer.get("style_name", "Beer"), int(aged_quality), int(aged_revenue)
					])
	# Brand decay tick (Stage 5B)
	if is_instance_valid(MarketManager):
		var brewed_style_id: String = ""
		if current_style != null:
			brewed_style_id = current_style.style_id
		MarketManager.tick_brand_decay(brewed_style_id)
	if check_win_condition():
		run_won = true
		_set_state(State.GAME_OVER)
		game_won.emit()
	elif check_loss_condition():
		run_won = false
		_set_state(State.GAME_OVER)
		game_lost.emit()
	else:
		_set_state(State.EQUIPMENT_MANAGE)

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
func get_recipe_cost(recipe: Dictionary) -> int:
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
	# Apply path ingredient discount (e.g., Mass-Market 20% off)
	if is_instance_valid(PathManager):
		total = int(total * PathManager.get_ingredient_discount())
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
	if is_instance_valid(PathManager) and PathManager.has_chosen_path():
		return PathManager.check_win_condition()
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
	var amount: float = BreweryExpansion.get_rent_amount() if is_instance_valid(BreweryExpansion) else 150.0
	balance -= amount
	balance_changed.emit(balance)
	rent_charged.emit(amount, balance)

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
	var demand_multiplier := MarketManager.get_demand_weight(style_id)
	var quality_mult := quality_to_multiplier(quality_score)
	var batch_mult := 1.0
	if is_instance_valid(EquipmentManager):
		batch_mult = EquipmentManager.active_bonuses.get("batch_size", 1.0)
	# Apply path batch multiplier (e.g., Mass-Market 2x)
	if is_instance_valid(PathManager):
		batch_mult *= PathManager.get_batch_multiplier()
	return current_style.base_price * quality_mult * demand_multiplier * batch_mult

# ---------------------------------------------------------------------------
# Brew execution — canonical entry point for a complete brew turn
# ---------------------------------------------------------------------------
## Executes the brew cycle: deduct cost → calculate quality → record brew →
## store result → advance state to RESULTS. Revenue is deferred to the SELL step.
## Returns the result Dictionary (with "final_score" key),
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

	# QA checkpoint toasts (Stage 1C)
	if is_instance_valid(ToastManager):
		var mash_temp: float = sliders.get("mashing", 65.0)
		var boil_min: float = sliders.get("boiling", 60.0)
		var yeast: Yeast = current_recipe.get("yeast", null) as Yeast

		var pre_boil: Dictionary = FailureSystem.calc_pre_boil_gravity(mash_temp)
		ToastManager.show_toast("Pre-Boil Gravity: OG %s — %s efficiency" % [pre_boil["og"], pre_boil["assessment"].capitalize()])

		var boil_check: Dictionary = FailureSystem.calc_boil_vigor(boil_min)
		ToastManager.show_toast("Boil Vigor: %s — %s" % [boil_check["vigor"].capitalize(), boil_check["dms_note"]])

		if yeast != null:
			var fg_check: Dictionary = FailureSystem.calc_final_gravity(mash_temp, yeast.attenuation_pct / 100.0)
			ToastManager.show_toast("Final Gravity: FG %s — Attenuation: %s%%" % [fg_check["fg"], fg_check["attenuation_pct"]])

	# Failure mode rolls (Stage 1C)
	var failure_result: Dictionary = FailureSystem.roll_failures(
		result["final_score"], sanitation_quality, temp_control_quality
	)
	result["final_score"] = failure_result["final_score"]
	result["infected"] = failure_result["infected"]
	result["infection_message"] = failure_result["infection_message"]
	result["off_flavor_tags"] = failure_result["off_flavor_tags"]
	result["off_flavor_message"] = failure_result["off_flavor_message"]
	result["failure_messages"] = failure_result["failure_messages"]

	record_brew(result["final_score"])

	# Reputation for high-quality brews (artisan path, quality > 80)
	if is_instance_valid(PathManager) and PathManager.has_chosen_path():
		if result["final_score"] > 80.0:
			PathManager.add_reputation(1)

	if is_instance_valid(BreweryExpansion):
		BreweryExpansion.record_brew()
		if BreweryExpansion.can_expand() and is_instance_valid(ToastManager):
			ToastManager.show_toast("Your brewery is ready to expand!")

	# Contract fulfillment check (Stage 4A)
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
			# Reputation for contract fulfillment (artisan path)
			if is_instance_valid(PathManager) and PathManager.has_chosen_path():
				PathManager.add_reputation(2)

	# Award research points
	var rp_earned: int = 2 + int(result["final_score"] / 20.0)
	ResearchManager.add_rp(rp_earned)
	result["rp_earned"] = rp_earned
	ToastManager.show_toast("Earned %d Research Points" % rp_earned)

	# Award XP to assigned staff
	if is_instance_valid(StaffManager):
		var xp_per_brew: int = 25 + int(result["final_score"] / 4.0)
		for phase_name in ["mashing", "boiling", "fermenting"]:
			var leveled: bool = StaffManager.award_xp(phase_name, xp_per_brew)
			if leveled:
				var staff_dict: Dictionary = StaffManager.get_staff_assigned_to(phase_name)
				if not staff_dict.is_empty() and is_instance_valid(ToastManager):
					ToastManager.show_toast("%s leveled up! (Lv.%d)" % [staff_dict.get("staff_name", "Staff"), staff_dict.get("level", 1)])

	if current_style:
		increment_taste(current_style.style_name)

	# Discovery rolls
	var brew_attributes: Array[String] = []
	if result.has("brew_attributes"):
		for attr in result["brew_attributes"]:
			brew_attributes.append(attr)
	var discovery_result: Dictionary = TasteSystem.roll_discoveries(brew_attributes, current_style.style_name if current_style else "")
	result["discovery_result"] = discovery_result

	# Generate tasting notes
	var tasting_notes: String = TasteSystem.generate_tasting_notes(
		brew_attributes, current_style.style_name if current_style else "", sliders
	)
	result["tasting_notes"] = tasting_notes

	# Discovery toasts
	if discovery_result.get("attribute_discovered", "") != "":
		var attr_name: String = TasteSystem.ATTRIBUTE_NAMES.get(
			discovery_result["attribute_discovered"],
			discovery_result["attribute_discovered"]
		)
		if is_instance_valid(ToastManager):
			ToastManager.show_toast("You noticed something... this beer has %s." % attr_name)

	if discovery_result.get("process_linked", "") != "":
		var linked_attr: String = discovery_result["process_linked"]
		var attr_name: String = TasteSystem.ATTRIBUTE_NAMES.get(linked_attr, linked_attr)
		var link_detail: String = discoveries[linked_attr].get("linked_detail", "")
		if is_instance_valid(ToastManager):
			ToastManager.show_toast("%s seems to come from %s." % [attr_name, link_detail])

	# Specialty beer aging (Stage 5B)
	if is_instance_valid(SpecialtyBeerManager) and current_style != null:
		if current_style.is_specialty and current_style.fermentation_turns > 1:
			var aging_entry: Dictionary = {
				"style_id": current_style.style_id,
				"style_name": current_style.style_name,
				"recipe": current_recipe.duplicate(true),
				"quality_base": result["final_score"],
				"turns_remaining": current_style.fermentation_turns,
				"variance_seed": randi(),
			}
			SpecialtyBeerManager.queue_beer(aging_entry)
			result["is_aging"] = true
			result["aging_turns"] = current_style.fermentation_turns
			if is_instance_valid(ToastManager):
				ToastManager.show_toast("%s sent to age for %d turns!" % [current_style.style_name, current_style.fermentation_turns])

	last_brew_result = result

	set_brewing(false)
	advance_state()

	return result

# ---------------------------------------------------------------------------
# Sell execution — called from SellOverlay when the player confirms distribution
# ---------------------------------------------------------------------------
## Executes the sell step: calculate multi-channel revenue, add to balance, record
## saturation. Returns {"total": float, "breakdown": Array} or {} if no brew result.
func execute_sell(allocations: Array, price_offset: float) -> Dictionary:
	if current_style == null or last_brew_result.is_empty():
		return {}
	var quality_score: float = last_brew_result.get("final_score", 0.0)
	var demand_mult: float = MarketManager.get_demand_multiplier(current_style.style_id)
	var volume_mod: float = MarketManager.calculate_volume_modifier(price_offset, quality_score)
	var quality_mult: float = quality_to_multiplier(quality_score)
	var adjusted_price: float = current_style.base_price * (1.0 + price_offset)

	var total: float = 0.0
	var breakdown: Array = []
	for alloc in allocations:
		var ch: Dictionary = MarketManager.get_channel(alloc.channel_id)
		if ch.is_empty():
			continue
		var rev: float = alloc.units * adjusted_price * ch.margin * quality_mult * demand_mult * volume_mod
		breakdown.append({
			"channel_id": alloc.channel_id,
			"channel_name": ch.name,
			"units": alloc.units,
			"price": adjusted_price,
			"margin": ch.margin,
			"revenue": rev,
		})
		total += rev

	add_revenue(total)
	last_brew_result["revenue"] = total
	last_brew_result["revenue_breakdown"] = breakdown
	last_brew_result["price_offset"] = price_offset
	MarketManager.record_brew(current_style.style_id)
	# Brand recognition gain for each channel with sales (Stage 5B)
	if is_instance_valid(MarketManager):
		for allocation in allocations:
			if allocation.get("units", 0) > 0:
				MarketManager.add_brand_recognition(current_style.style_id, allocation["channel_id"])
	return {"total": total, "breakdown": breakdown}

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
	sanitation_quality = 50
	if is_instance_valid(EquipmentManager):
		EquipmentManager.reset()
	ResearchManager.reset()
	if is_instance_valid(StaffManager):
		StaffManager.reset()
	if is_instance_valid(BreweryExpansion):
		BreweryExpansion.reset()
	if is_instance_valid(ContractManager):
		ContractManager.reset()
	if is_instance_valid(CompetitionManager):
		CompetitionManager.reset()
	if is_instance_valid(PathManager):
		PathManager.reset()
	if is_instance_valid(SpecialtyBeerManager):
		SpecialtyBeerManager.reset()
	if is_instance_valid(EquipmentManager):
		EquipmentManager.initialize_starting_equipment()
	if is_instance_valid(MarketManager):
		MarketManager.initialize()
	_set_state(State.EQUIPMENT_MANAGE)
