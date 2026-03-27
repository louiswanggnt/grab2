extends Node

## Economy manager: sells items for coins, handles upgrades.
## Upgrade cost formula (GDD): cost = base_cost * (1 + level * cost_scaling)

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

signal money_changed(new_total: int)
signal upgrade_purchased(upgrade_id: String, new_level: int)
signal check_completed(round_earnings: int)
signal relic_found(item: Node2D)

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

const UPGRADES: Dictionary = {
	# Small upgrades (incremental)
	"magnet_power": { "base_cost": 50, "max_level": 10, "effect_per_level": 1.0 },
	"retrieve_speed": { "base_cost": 80, "max_level": 8, "effect_per_level": 0.1 },
	"boat_speed": { "base_cost": 40, "max_level": 5, "effect_per_level": 0.1 },
	"steering": { "base_cost": 60, "max_level": 5, "effect_per_level": 0.15 },
	# Big upgrades (unlockable equipment)
	"new_boat_1": { "base_cost": 500, "max_level": 1, "effect_per_level": 1.0 },
	"new_boat_2": { "base_cost": 800, "max_level": 1, "effect_per_level": 1.0 },
	"new_magnet_1": { "base_cost": 800, "max_level": 1, "effect_per_level": 1.0 },
	"new_magnet_2": { "base_cost": 1200, "max_level": 1, "effect_per_level": 1.0 },
}

# ---------------------------------------------------------------------------
# Exports
# ---------------------------------------------------------------------------

@export_range(0.1, 2.0, 0.1) var cost_scaling: float = 0.5
@export_range(20, 50, 5) var chest_min_reward: int = 30
@export_range(80, 200, 10) var chest_max_reward: int = 120

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

var money: int = 0
var _upgrade_levels: Dictionary = {
	"magnet_power": 0,
	"retrieve_speed": 0,
	"boat_speed": 0,
	"steering": 0,
	"new_boat_1": 0,
	"new_boat_2": 0,
	"new_magnet_1": 0,
	"new_magnet_2": 0,
}

# ---------------------------------------------------------------------------
# Public API — money
# ---------------------------------------------------------------------------

func add_money(amount: int) -> void:
	if amount <= 0:
		return
	money += amount
	money_changed.emit(money)


func get_money() -> int:
	return money


# ---------------------------------------------------------------------------
# Public API — item processing (CHECK phase)
# ---------------------------------------------------------------------------

func process_check(items: Array) -> int:
	var earnings: int = 0

	for item in items:
		if not is_instance_valid(item):
			continue
		# Read value from metal object (set by set_metal_properties)
		if "value" in item:
			earnings += item.value
		else:
			earnings += 10  # Fallback

	if earnings > 0:
		add_money(earnings)
	check_completed.emit(earnings)
	return earnings


# ---------------------------------------------------------------------------
# Public API — upgrades
# ---------------------------------------------------------------------------

func get_upgrade_level(upgrade_id: String) -> int:
	return _upgrade_levels.get(upgrade_id, 0)


func get_upgrade_cost(upgrade_id: String) -> int:
	var config: Dictionary = UPGRADES.get(upgrade_id, {})
	if config.is_empty():
		return 0
	var level: int = _upgrade_levels.get(upgrade_id, 0)
	if level >= config.max_level:
		return 0
	return int(config.base_cost * (1.0 + level * cost_scaling))


func get_upgrade_effect(upgrade_id: String) -> float:
	var config: Dictionary = UPGRADES.get(upgrade_id, {})
	if config.is_empty():
		return 0.0
	var level: int = _upgrade_levels.get(upgrade_id, 0)
	return level * config.effect_per_level


func can_afford_upgrade(upgrade_id: String) -> bool:
	var cost: int = get_upgrade_cost(upgrade_id)
	return cost > 0 and money >= cost


func try_purchase_upgrade(upgrade_id: String) -> bool:
	var config: Dictionary = UPGRADES.get(upgrade_id, {})
	if config.is_empty():
		return false

	var level: int = _upgrade_levels.get(upgrade_id, 0)
	if level >= config.max_level:
		return false

	var cost: int = get_upgrade_cost(upgrade_id)
	if money < cost:
		return false

	money -= cost
	_upgrade_levels[upgrade_id] = level + 1
	money_changed.emit(money)
	upgrade_purchased.emit(upgrade_id, level + 1)
	return true


# ---------------------------------------------------------------------------
# Private
# ---------------------------------------------------------------------------

