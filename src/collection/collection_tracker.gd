extends Node

## Tracks all items the player has ever collected.
## Persists across dives within a session. Keyed by "{tier_id}_{variant_index}".

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

signal collection_updated()

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

## { "light_0": 10, "medium_2": 3, ... }
var _collected: Dictionary = {}

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Record that an item was collected. Call once per item upon surface arrival.
func record_item(tier_id: String, variant_index: int) -> void:
	var key: String = _make_key(tier_id, variant_index)
	_collected[key] = _collected.get(key, 0) + 1
	collection_updated.emit()


## Get how many times a specific variant has been collected.
func get_count(tier_id: String, variant_index: int) -> int:
	return _collected.get(_make_key(tier_id, variant_index), 0)


## Whether the player has ever collected this variant.
func is_discovered(tier_id: String, variant_index: int) -> bool:
	return get_count(tier_id, variant_index) > 0


## Get total number of unique variants discovered.
func get_discovered_count() -> int:
	var count: int = 0
	for key in _collected:
		if _collected[key] > 0:
			count += 1
	return count


## Get total number of possible variants (from GameConfig).
func get_total_variant_count() -> int:
	var total: int = 0
	for tier in GameConfig.METAL_TIERS:
		total += tier.variants.size()
	return total


## Get total items collected (sum of all counts).
func get_total_collected() -> int:
	var total: int = 0
	for key in _collected:
		total += _collected[key]
	return total


## Get a snapshot of all collection data for UI display.
## Returns Array of { tier_id, variant_index, weight, size, value, count, discovered }
func get_all_entries() -> Array:
	var entries: Array = []
	for tier in GameConfig.METAL_TIERS:
		var tier_id: String = tier.id
		var variants: Array = tier.variants
		for vi in range(variants.size()):
			var count: int = get_count(tier_id, vi)
			entries.append({
				"tier_id": tier_id,
				"variant_index": vi,
				"weight": tier.weight,
				"size": tier.size,
				"value": variants[vi].value,
				"count": count,
				"discovered": count > 0,
			})
	return entries


# ---------------------------------------------------------------------------
# Private
# ---------------------------------------------------------------------------

func _make_key(tier_id: String, variant_index: int) -> String:
	return "%s_%d" % [tier_id, variant_index]
