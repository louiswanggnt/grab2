extends Control

## Collection / Museum panel — shows all item variants and how many collected.
## Undiscovered items show silhouette + "???" name.

signal closed()

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

const ITEM_ICON_SIZE: float = 48.0
const UNDISCOVERED_COLOR: Color = Color(0.15, 0.15, 0.15, 1.0)
const DISCOVERED_LABEL_COLOR: Color = Color(1.0, 1.0, 1.0, 1.0)
const UNDISCOVERED_LABEL_COLOR: Color = Color(0.4, 0.4, 0.4, 1.0)

# ---------------------------------------------------------------------------
# Child references (built in _ready)
# ---------------------------------------------------------------------------

var _scroll: ScrollContainer = null
var _grid: GridContainer = null
var _title_label: Label = null
var _progress_label: Label = null
var _close_btn: Button = null
var _overlay: ColorRect = null

# ---------------------------------------------------------------------------
# Built-in
# ---------------------------------------------------------------------------

func _ready() -> void:
	visible = false
	_build_ui()


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

func show_collection(tracker: Node) -> void:
	_populate(tracker)
	visible = true
	# Fade in
	modulate = Color(1, 1, 1, 0)
	var tw: Tween = create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.2)


func hide_collection() -> void:
	visible = false


# ---------------------------------------------------------------------------
# UI Construction
# ---------------------------------------------------------------------------

func _build_ui() -> void:
	# Full-screen overlay
	_overlay = ColorRect.new()
	_overlay.name = "Overlay"
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.color = Color(0, 0, 0, 0.8)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_overlay)

	# Center panel
	var panel: PanelContainer = PanelContainer.new()
	panel.name = "Panel"
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -320.0
	panel.offset_top = -450.0
	panel.offset_right = 320.0
	panel.offset_bottom = 450.0
	add_child(panel)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	# Title
	_title_label = Label.new()
	_title_label.text = "收藏庫"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 28)
	vbox.add_child(_title_label)

	# Progress
	_progress_label = Label.new()
	_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_progress_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(_progress_label)

	# Separator
	var sep: HSeparator = HSeparator.new()
	vbox.add_child(sep)

	# Scroll area
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(_scroll)

	_grid = GridContainer.new()
	_grid.columns = 1
	_grid.add_theme_constant_override("v_separation", 6)
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_grid)

	# Close button
	_close_btn = Button.new()
	_close_btn.text = "關閉"
	_close_btn.custom_minimum_size = Vector2(0, 44)
	_close_btn.add_theme_font_size_override("font_size", 20)
	_close_btn.pressed.connect(_on_close)
	vbox.add_child(_close_btn)


# ---------------------------------------------------------------------------
# Populate grid from tracker data
# ---------------------------------------------------------------------------

func _populate(tracker: Node) -> void:
	# Clear old entries
	for child in _grid.get_children():
		child.queue_free()

	var entries: Array = tracker.get_all_entries()
	var discovered_count: int = tracker.get_discovered_count()
	var total_count: int = tracker.get_total_variant_count()
	_progress_label.text = "已發現: %d / %d" % [discovered_count, total_count]

	# Group by tier
	var current_tier: String = ""
	for entry in entries:
		# Tier header
		if entry.tier_id != current_tier:
			current_tier = entry.tier_id
			var header: Label = Label.new()
			header.text = "── %s ──" % _tier_display_name(current_tier)
			header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			header.add_theme_font_size_override("font_size", 18)
			header.add_theme_color_override("font_color", Color(0.8, 0.7, 0.4))
			_grid.add_child(header)

		# Item row
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)

		# Icon area
		var icon_rect: ColorRect = ColorRect.new()
		icon_rect.custom_minimum_size = Vector2(ITEM_ICON_SIZE, ITEM_ICON_SIZE)

		if entry.discovered:
			# Try loading sprite
			var sprite_path: String = _get_sprite_path(entry.tier_id, entry.variant_index)
			if ResourceLoader.exists(sprite_path):
				var tex_rect: TextureRect = TextureRect.new()
				tex_rect.texture = load(sprite_path)
				tex_rect.custom_minimum_size = Vector2(ITEM_ICON_SIZE, ITEM_ICON_SIZE)
				tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				tex_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
				row.add_child(tex_rect)
			else:
				# Colored placeholder for discovered but no sprite file
				icon_rect.color = _tier_color(entry.tier_id)
				row.add_child(icon_rect)
		else:
			# Undiscovered — dark silhouette
			icon_rect.color = UNDISCOVERED_COLOR
			row.add_child(icon_rect)

		# Name
		var name_lbl: Label = Label.new()
		name_lbl.custom_minimum_size = Vector2(200, 0)
		name_lbl.add_theme_font_size_override("font_size", 16)
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if entry.discovered:
			name_lbl.text = "metal_%s%02d" % [entry.tier_id, entry.variant_index + 1]
			name_lbl.add_theme_color_override("font_color", DISCOVERED_LABEL_COLOR)
		else:
			name_lbl.text = "???"
			name_lbl.add_theme_color_override("font_color", UNDISCOVERED_LABEL_COLOR)
		row.add_child(name_lbl)

		# Value (only if discovered)
		var value_lbl: Label = Label.new()
		value_lbl.custom_minimum_size = Vector2(60, 0)
		value_lbl.add_theme_font_size_override("font_size", 16)
		value_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		if entry.discovered:
			value_lbl.text = "$%d" % entry.value
		else:
			value_lbl.text = "---"
			value_lbl.add_theme_color_override("font_color", UNDISCOVERED_LABEL_COLOR)
		row.add_child(value_lbl)

		# Count
		var count_lbl: Label = Label.new()
		count_lbl.custom_minimum_size = Vector2(70, 0)
		count_lbl.add_theme_font_size_override("font_size", 16)
		count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		if entry.discovered:
			count_lbl.text = "×%d" % entry.count
		else:
			count_lbl.text = ""
		row.add_child(count_lbl)

		_grid.add_child(row)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _get_sprite_path(tier_id: String, variant_index: int) -> String:
	# Try numbered variant first, then fallback
	var numbered: String = "res://assets/sprites/items/metal_%s%02d.png" % [
		tier_id, variant_index + 1]
	if ResourceLoader.exists(numbered):
		return numbered
	return "res://assets/sprites/items/metal_%s.png" % tier_id


func _tier_display_name(tier_id: String) -> String:
	match tier_id:
		"light": return "輕型"
		"medium": return "中型"
		"heavy": return "重型"
		"rare": return "稀有"
		_: return tier_id


func _tier_color(tier_id: String) -> Color:
	match tier_id:
		"light": return Color(0.55, 0.45, 0.35)
		"medium": return Color(0.6, 0.5, 0.3)
		"heavy": return Color(0.7, 0.55, 0.25)
		"rare": return Color(0.85, 0.65, 0.15)
		_: return Color(0.5, 0.5, 0.5)


func _on_close() -> void:
	hide_collection()
	closed.emit()
