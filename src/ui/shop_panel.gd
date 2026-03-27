extends Control

## Upgrade shop shown during CHECK state.

signal continue_pressed()

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

const SMALL_UPGRADES: Array = [
	{ "id": "magnet_power", "name": "磁力強度", "desc": "+1 吸附上限" },
	{ "id": "retrieve_speed", "name": "回收速度", "desc": "+10% 速度" },
	{ "id": "boat_speed", "name": "船速", "desc": "+10% 速度" },
	{ "id": "steering", "name": "操控性", "desc": "+15% 轉向" },
]

const BIG_UPGRADES: Array = [
	{ "id": "new_boat_1", "name": "快艇", "desc": "船速 +50%，體積較小" },
	{ "id": "new_boat_2", "name": "重型拖船", "desc": "船速 -20%，穩定性 +100%" },
	{ "id": "new_magnet_1", "name": "雙鉤磁鐵", "desc": "吸附上限 ×2" },
	{ "id": "new_magnet_2", "name": "電磁鐵", "desc": "吸附範圍 +50%" },
]

# ---------------------------------------------------------------------------
# Child references
# ---------------------------------------------------------------------------

@onready var _money_display: Label = $Panel/VBox/MoneyDisplay
@onready var _small_container: VBoxContainer = $Panel/VBox/SmallUpgrades
@onready var _big_container: VBoxContainer = $Panel/VBox/BigUpgrades
@onready var _continue_btn: Button = $Panel/VBox/ContinueButton

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

var _economy: Node = null
var _upgrade_rows: Dictionary = {}

# ---------------------------------------------------------------------------
# Built-in
# ---------------------------------------------------------------------------

func _ready() -> void:
	_continue_btn.pressed.connect(_on_continue_pressed)
	visible = false


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Show the shop with the given economy reference.
func show_shop(economy: Node) -> void:
	_economy = economy
	_build_rows()
	_refresh_all()
	visible = true


## Hide the shop panel.
func hide_shop() -> void:
	visible = false


# ---------------------------------------------------------------------------
# Row building
# ---------------------------------------------------------------------------

func _build_rows() -> void:
	for child in _small_container.get_children():
		child.free()
	for child in _big_container.get_children():
		child.free()
	_upgrade_rows.clear()

	for info in SMALL_UPGRADES:
		_add_upgrade_row(_small_container, info, false)

	for info in BIG_UPGRADES:
		_add_upgrade_row(_big_container, info, true)


func _add_upgrade_row(container: VBoxContainer, info: Dictionary, is_big: bool) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var name_lbl: Label = Label.new()
	name_lbl.text = info.name
	name_lbl.custom_minimum_size = Vector2(90, 0)
	name_lbl.add_theme_font_size_override("font_size", 18)
	row.add_child(name_lbl)

	var level_lbl: Label = Label.new()
	level_lbl.custom_minimum_size = Vector2(120, 0)
	level_lbl.add_theme_font_size_override("font_size", 16)
	row.add_child(level_lbl)

	var cost_lbl: Label = Label.new()
	cost_lbl.custom_minimum_size = Vector2(70, 0)
	cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cost_lbl.add_theme_font_size_override("font_size", 16)
	row.add_child(cost_lbl)

	var buy_btn: Button = Button.new()
	buy_btn.custom_minimum_size = Vector2(72, 36)
	buy_btn.add_theme_font_size_override("font_size", 16)
	buy_btn.pressed.connect(_on_buy_pressed.bind(info.id))
	row.add_child(buy_btn)

	container.add_child(row)

	_upgrade_rows[info.id] = {
		"label": level_lbl,
		"cost_label": cost_lbl,
		"buy_btn": buy_btn,
		"desc": info.desc,
		"is_big": is_big,
	}


# ---------------------------------------------------------------------------
# Refresh display
# ---------------------------------------------------------------------------

func _refresh_all() -> void:
	if not _economy:
		return
	_money_display.text = "持有：$%d" % _economy.get_money()
	for id in _upgrade_rows:
		_refresh_row(id)


func _refresh_row(id: String) -> void:
	var row_data: Dictionary = _upgrade_rows[id]
	var level: int = _economy.get_upgrade_level(id)
	var cost: int = _economy.get_upgrade_cost(id)
	var can_buy: bool = _economy.can_afford_upgrade(id)
	var is_maxed: bool = cost == 0

	if row_data.is_big:
		if is_maxed:
			row_data.label.text = row_data.desc
			row_data.cost_label.text = "已解鎖"
			row_data.buy_btn.text = "---"
			row_data.buy_btn.disabled = true
		else:
			row_data.label.text = row_data.desc
			row_data.cost_label.text = "$%d" % cost
			row_data.buy_btn.text = "即將推出"
			row_data.buy_btn.disabled = true
	else:
		if is_maxed:
			row_data.label.text = "Lv.%d (MAX)" % level
			row_data.cost_label.text = "---"
			row_data.buy_btn.text = "已滿"
			row_data.buy_btn.disabled = true
		else:
			row_data.label.text = "Lv.%d  %s" % [level, row_data.desc]
			row_data.cost_label.text = "$%d" % cost
			row_data.buy_btn.text = "購買"
			row_data.buy_btn.disabled = not can_buy

	if not can_buy and not is_maxed and not row_data.is_big:
		row_data.cost_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	else:
		row_data.cost_label.remove_theme_color_override("font_color")


# ---------------------------------------------------------------------------
# Callbacks
# ---------------------------------------------------------------------------

func _on_buy_pressed(upgrade_id: String) -> void:
	if not _economy:
		return
	var row_data: Dictionary = _upgrade_rows.get(upgrade_id, {})
	if row_data.is_empty():
		return
	row_data.buy_btn.disabled = true  # Prevent double-tap
	if _economy.try_purchase_upgrade(upgrade_id):
		_refresh_all()


func _on_continue_pressed() -> void:
	hide_shop()
	continue_pressed.emit()
