@tool
extends EditorScript

## Run this script once in the Godot editor (Script menu → Run) to generate
## all MVP ItemData .tres resource files under data/items/.
##
## Re-running is safe — it will overwrite existing files.
##
## Items generated:
##   Metals  (5): iron_nail, copper_pipe, silver_bar, gold_nugget, tin_can_scrap
##   Junk    (2): rusty_can, bent_nail
##   Relics  (1): ancient_compass
##   Chests  (1): iron_chest

func _run() -> void:
	_generate_metals()
	_generate_junk()
	_generate_relics()
	_generate_chests()
	print("generate_items: all MVP resources written.")


# ---------------------------------------------------------------------------
# Metal definitions — covers all four rarity tiers
# ---------------------------------------------------------------------------

func _generate_metals() -> void:
	var dir_path: String = "res://data/items/metals/"

	# COMMON — shallow water (800-1200 px)
	_save(_build_item(
		"metal_iron_nail",
		"鐵釘",
		ItemData.Category.METAL,
		ItemData.Rarity.COMMON,
		8,
		0.5,
		Vector2(16.0, 16.0),
		800.0, 1400.0
	), dir_path + "metal_iron_nail.tres")

	# UNCOMMON — mid water (1000-1600 px)
	_save(_build_item(
		"metal_copper_pipe",
		"銅管",
		ItemData.Category.METAL,
		ItemData.Rarity.UNCOMMON,
		25,
		1.5,
		Vector2(24.0, 48.0),
		1000.0, 1800.0
	), dir_path + "metal_copper_pipe.tres")

	# RARE — deep water (1400-2000 px)
	_save(_build_item(
		"metal_silver_bar",
		"銀錠",
		ItemData.Category.METAL,
		ItemData.Rarity.RARE,
		60,
		2.5,
		Vector2(32.0, 24.0),
		1400.0, 2000.0
	), dir_path + "metal_silver_bar.tres")

	# EPIC — deepest zone only (1700-2000 px)
	_save(_build_item(
		"metal_gold_nugget",
		"金塊",
		ItemData.Category.METAL,
		ItemData.Rarity.EPIC,
		120,
		4.0,
		Vector2(32.0, 32.0),
		1700.0, 2000.0
	), dir_path + "metal_gold_nugget.tres")

	# Second COMMON for variety — same depth as iron nail
	_save(_build_item(
		"metal_iron_chain",
		"鐵鏈",
		ItemData.Category.METAL,
		ItemData.Rarity.COMMON,
		10,
		1.2,
		Vector2(16.0, 32.0),
		800.0, 1300.0
	), dir_path + "metal_iron_chain.tres")


# ---------------------------------------------------------------------------
# Junk definitions — fixed COMMON, low value, shallow depth
# ---------------------------------------------------------------------------

func _generate_junk() -> void:
	var dir_path: String = "res://data/items/junk/"

	_save(_build_item(
		"junk_rusty_can",
		"生鏽鐵罐",
		ItemData.Category.JUNK,
		ItemData.Rarity.COMMON,
		1,
		0.6,
		Vector2(20.0, 24.0),
		800.0, 1400.0
	), dir_path + "junk_rusty_can.tres")

	_save(_build_item(
		"junk_bent_nail",
		"彎釘子",
		ItemData.Category.JUNK,
		ItemData.Rarity.COMMON,
		0,
		0.5,
		Vector2(12.0, 12.0),
		800.0, 1200.0
	), dir_path + "junk_bent_nail.tres")


# ---------------------------------------------------------------------------
# Relic definitions — RARE tier, triggers Roguelite upgrade on retrieval
# ---------------------------------------------------------------------------

func _generate_relics() -> void:
	var dir_path: String = "res://data/items/relics/"

	_save(_build_item(
		"relic_ancient_compass",
		"古代羅盤",
		ItemData.Category.RELIC,
		ItemData.Rarity.RARE,
		50,
		2.0,
		Vector2(28.0, 28.0),
		1200.0, 2000.0
	), dir_path + "relic_ancient_compass.tres")


# ---------------------------------------------------------------------------
# Chest definitions — UNCOMMON tier, high weight, high reward
# ---------------------------------------------------------------------------

func _generate_chests() -> void:
	var dir_path: String = "res://data/items/chests/"

	_save(_build_item(
		"chest_iron",
		"鐵皮箱",
		ItemData.Category.CHEST,
		ItemData.Rarity.UNCOMMON,
		80,
		5.0,
		Vector2(48.0, 40.0),
		1400.0, 2000.0
	), dir_path + "chest_iron.tres")


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _build_item(
	id: String,
	display_name: String,
	category: ItemData.Category,
	rarity: ItemData.Rarity,
	value: int,
	weight: float,
	size: Vector2,
	depth_min: float,
	depth_max: float
) -> ItemData:
	var item: ItemData = ItemData.new()
	item.id = id
	item.display_name = display_name
	item.category = category
	item.rarity = rarity
	item.value = value
	item.weight = weight
	item.size = size
	item.depth_min = depth_min
	item.depth_max = depth_max
	return item


func _save(item: ItemData, path: String) -> void:
	var err: Error = ResourceSaver.save(item, path)
	if err != OK:
		push_error("generate_items: failed to save %s (error %d)" % [path, err])
	else:
		print("generate_items: saved %s" % path)
