extends Node

## RunModifierManager — computes perk/modifier effects for the active run.
## Stateless: all methods take a meta manager reference and compute effects.

func get_starting_cash_multiplier(meta: Node) -> float:
	var mult: float = 1.0
	if meta.has_active_perk("nest_egg"):
		mult *= 1.05
	if meta.has_active_modifier("budget_brewery"):
		mult *= 0.5
	return mult

func get_rp_bonus(meta: Node) -> int:
	if meta.has_active_perk("quick_study"):
		return 1
	return 0

func get_rent_multiplier(meta: Node) -> float:
	if meta.has_active_perk("landlords_friend"):
		return 0.9
	return 1.0

func get_quality_bonus(meta: Node) -> float:
	var bonus: float = 0.0
	if meta.has_active_perk("style_specialist"):
		bonus += 5.0
	if meta.has_active_modifier("master_brewer"):
		bonus += 10.0
	return bonus

func get_demand_modifier(meta: Node) -> float:
	if meta.has_active_modifier("tough_market"):
		return 0.8
	if meta.has_active_modifier("generous_market"):
		return 1.2
	return 1.0

func get_infection_immune_brews(meta: Node) -> int:
	if meta.has_active_modifier("lucky_break"):
		return 5
	return 0

func get_ingredient_availability(meta: Node) -> float:
	if meta.has_active_modifier("ingredient_shortage"):
		return 0.6
	return 1.0
