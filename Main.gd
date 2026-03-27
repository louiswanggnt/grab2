extends Node2D

## Game orchestrator. Wires magnet, boat, economy, UI, and timer together.

@onready var metal_container: Node2D = $MetalContainer
@onready var boat: CharacterBody2D = $Boat

var magnet_scene: PackedScene = preload("res://Magnet.tscn")
var metal_scene: PackedScene = preload("res://MetalObject.tscn")
var fish_scene: PackedScene = preload("res://Fish.tscn")
var hud_scene: PackedScene = preload("res://src/ui/hud.tscn")
var shop_scene: PackedScene = preload("res://src/ui/shop_panel.tscn")
var round_end_scene: PackedScene = preload("res://src/ui/round_end_screen.tscn")
var collection_panel_scene: PackedScene = preload("res://src/ui/collection_panel.tscn")

var magnet: Area2D = null
var economy: Node = null
var round_timer: Node = null
var round_stats: Node = null
var collection_tracker: Node = null
var hud: Control = null
var shop: Control = null
var round_end: Control = null
var collection_panel: Control = null
var _round_ending: bool = false
var _base_attach_count: int = 0
var _base_retrieve_speed: float = 0.0
var _base_boat_speed: float = 0.0
var _base_steering_power: float = 0.0

# UI icon buttons (shown on left side)
var _shop_icon: Button = null
var _collection_icon: Button = null

# Item counting animation state
var _counting_items: Array = []
var _counting_tween: Tween = null
var _current_dive_earnings: int = 0

func _ready() -> void:
	# Create economy system
	economy = load("res://src/economy/economy_system.gd").new()
	economy.name = "EconomySystem"
	add_child(economy)

	# Create round timer
	round_timer = load("res://src/main/round_timer.gd").new()
	round_timer.name = "RoundTimer"
	round_timer.round_duration = GameConfig.ROUND_DURATION
	add_child(round_timer)

	# Create round stats tracker
	round_stats = load("res://src/main/round_stats.gd").new()
	round_stats.name = "RoundStats"
	add_child(round_stats)

	# Create collection tracker
	collection_tracker = load("res://src/collection/collection_tracker.gd").new()
	collection_tracker.name = "CollectionTracker"
	add_child(collection_tracker)

	# Instantiate magnet at boat's mount point
	magnet = magnet_scene.instantiate()
	add_child(magnet)
	var mount_pos: Vector2 = boat.get_node("MagnetMount").global_position
	magnet.position = mount_pos
	magnet.mount_position = mount_pos
	magnet.surface_y = mount_pos.y
	magnet.round_timer = round_timer

	# Capture base values before any upgrades
	_base_attach_count = magnet.max_attach_count
	_base_retrieve_speed = magnet.base_retrieve_speed
	_base_boat_speed = boat.base_speed
	_base_steering_power = magnet.steering_power

	# Create HUD
	hud = hud_scene.instantiate()
	$UI.add_child(hud)
	hud.setup(magnet.max_attach_count)

	# Create Shop Panel
	shop = shop_scene.instantiate()
	$UI.add_child(shop)
	shop.continue_pressed.connect(_on_shop_continue)

	# Create Round End Screen
	round_end = round_end_scene.instantiate()
	$UI.add_child(round_end)
	round_end.retry_pressed.connect(_on_retry)

	# Create Collection Panel
	collection_panel = collection_panel_scene.instantiate()
	$UI.add_child(collection_panel)
	collection_panel.closed.connect(_on_collection_closed)

	# Create icon buttons (left side)
	_create_shop_icon()
	_create_collection_icon()

	# Wire magnet signals
	magnet.state_changed.connect(_on_magnet_state_changed)
	magnet.surface_reached.connect(_on_magnet_surface_reached)
	round_timer.time_updated.connect(_on_timer_updated)
	round_timer.time_expired.connect(_on_timer_expired)

	# Wire HUD signals
	round_timer.time_updated.connect(hud.on_time_updated)
	round_timer.urgent_mode_entered.connect(hud.on_urgent_mode)
	economy.money_changed.connect(hud.on_money_changed)
	magnet.item_contacted.connect(hud.on_item_attached)
	magnet.state_changed.connect(hud.on_magnet_state_changed)

	# Position seabed from GameConfig
	var seabed: StaticBody2D = $Seabed
	seabed.position.y = GameConfig.SEABED_Y

	# Spawn metal objects and decorative fish
	_spawn_metals()
	_spawn_fish()


func _process(_delta: float) -> void:
	if not magnet:
		return
	var mount_pos: Vector2 = boat.get_node("MagnetMount").global_position
	magnet.mount_position = mount_pos

	if magnet.get_state() == 0:  # IDLE — stick to boat
		magnet.position = mount_pos
	elif magnet.get_state() == 1:  # SINKING — sync X with boat
		magnet.position.x = mount_pos.x


# ---------------------------------------------------------------------------
# Icon Buttons — 左側按鈕列（純手動觸發，不受磁鐵狀態控制）
# ---------------------------------------------------------------------------

func _create_shop_icon() -> void:
	_shop_icon = Button.new()
	_shop_icon.name = "ShopIcon"
	_shop_icon.text = "🛒"
	_shop_icon.custom_minimum_size = GameConfig.SHOP_ICON_SIZE
	_shop_icon.add_theme_font_size_override("font_size", 28)
	_shop_icon.anchors_preset = Control.PRESET_TOP_LEFT
	_shop_icon.position = Vector2(
		GameConfig.SHOP_ICON_MARGIN_LEFT,
		GameConfig.SHOP_ICON_MARGIN_TOP
	)
	_shop_icon.visible = true  # Always visible
	_shop_icon.pressed.connect(_on_shop_icon_pressed)
	$UI.add_child(_shop_icon)


func _create_collection_icon() -> void:
	_collection_icon = Button.new()
	_collection_icon.name = "CollectionIcon"
	_collection_icon.text = "📦"
	_collection_icon.custom_minimum_size = GameConfig.SHOP_ICON_SIZE
	_collection_icon.add_theme_font_size_override("font_size", 28)
	_collection_icon.anchors_preset = Control.PRESET_TOP_LEFT
	# Position below the shop icon
	_collection_icon.position = Vector2(
		GameConfig.SHOP_ICON_MARGIN_LEFT,
		GameConfig.SHOP_ICON_MARGIN_TOP + GameConfig.SHOP_ICON_SIZE.y + 12.0
	)
	_collection_icon.visible = true
	_collection_icon.pressed.connect(_on_collection_icon_pressed)
	$UI.add_child(_collection_icon)


func _on_shop_icon_pressed() -> void:
	_show_shop()


func _on_collection_icon_pressed() -> void:
	collection_panel.show_collection(collection_tracker)


func _on_collection_closed() -> void:
	pass  # Panel handles its own visibility


# ---------------------------------------------------------------------------
# Item Counting Animation — 物資清點動畫（一個一個消失 + 金錢逐筆增加）
# ---------------------------------------------------------------------------

func _start_counting(items: Array) -> void:
	_current_dive_earnings = 0
	_counting_items = []

	# Reparent items from magnet's CatchPoint to Main — break physics link with boat
	for item in items:
		if not is_instance_valid(item):
			continue
		var gpos: Vector2 = item.global_position
		if item.get_parent():
			item.get_parent().remove_child(item)
		add_child(item)
		item.global_position = gpos
		# Disable all physics so RigidBody2D won't push the boat
		if item is RigidBody2D:
			item.freeze = true
			item.collision_layer = 0
			item.collision_mask = 0
		_counting_items.append(item)

	magnet.clear_attached_list()
	_count_next_item()


func _count_next_item() -> void:
	# Skip invalid items
	while not _counting_items.is_empty():
		var item: Node2D = _counting_items[0]
		if is_instance_valid(item):
			break
		_counting_items.pop_front()

	if _counting_items.is_empty():
		_finish_counting()
		return

	var item: Node2D = _counting_items.pop_front()
	var value: int = item.value if "value" in item else 10

	# Animate: float up + fade out
	_counting_tween = create_tween()
	_counting_tween.tween_property(item, "position:y", item.position.y - 50.0, 0.25)
	_counting_tween.parallel().tween_property(item, "modulate:a", 0.0, 0.25)
	_counting_tween.tween_callback(func():
		_current_dive_earnings += value
		economy.add_money(value)  # Triggers money_changed → HUD updates
		if is_instance_valid(item):
			item.queue_free()
		# Small delay before next item
		get_tree().create_timer(0.15).timeout.connect(_count_next_item, CONNECT_ONE_SHOT)
	)


func _finish_counting() -> void:
	round_stats.record_dive(_current_dive_earnings)
	_counting_items.clear()
	if _round_ending:
		_show_round_end()


## Cancel counting animation and instantly process all remaining items.
func _cancel_counting_and_process() -> void:
	if _counting_tween and _counting_tween.is_running():
		_counting_tween.kill()
	for item in _counting_items:
		if is_instance_valid(item):
			var value: int = item.value if "value" in item else 10
			_current_dive_earnings += value
			economy.add_money(value)
			item.queue_free()
	_counting_items.clear()
	if _current_dive_earnings > 0:
		round_stats.record_dive(_current_dive_earnings)
	_current_dive_earnings = 0
	if _round_ending:
		_show_round_end()


# ---------------------------------------------------------------------------
# Spawners
# ---------------------------------------------------------------------------

func _spawn_metals() -> void:
	for tier in GameConfig.METAL_TIERS:
		var tier_id: String = tier.id
		var w: float = tier.weight
		var s: float = tier.size
		var count: int = tier.count
		var variants: Array = tier.variants
		var variant_count: int = variants.size()

		for i in range(count):
			var metal: RigidBody2D = metal_scene.instantiate()
			metal_container.add_child(metal)

			# Pick a random variant for value
			var vi: int = randi() % variant_count
			var v: int = variants[vi].value

			metal.set_metal_properties(w, v, s, tier_id, vi)
			metal.freeze = true

			# Position on seabed area
			metal.position = Vector2(
				randf_range(GameConfig.METAL_SPAWN_X_MIN, GameConfig.METAL_SPAWN_X_MAX),
				GameConfig.METAL_SEABED_TOP_Y - s / 2.0 - randf_range(0, s * 2.0)
			)

			# Random rotation for natural scatter look
			metal.rotation = randf_range(
				-GameConfig.METAL_SCATTER_ROTATION_MAX,
				GameConfig.METAL_SCATTER_ROTATION_MAX
			)


func _spawn_fish() -> void:
	for i in range(GameConfig.FISH_COUNT):
		var fish: Node2D = fish_scene.instantiate()
		fish.position = Vector2(
			randf_range(GameConfig.FISH_SPAWN_X_MIN, GameConfig.FISH_SPAWN_X_MAX),
			randf_range(GameConfig.FISH_SPAWN_Y_MIN, GameConfig.FISH_SPAWN_Y_MAX)
		)
		var s: float = randf_range(GameConfig.FISH_SCALE_MIN, GameConfig.FISH_SCALE_MAX)
		fish.scale *= s
		add_child(fish)


# ---------------------------------------------------------------------------
# Signal callbacks
# ---------------------------------------------------------------------------

func _on_magnet_state_changed(_old_state: int, new_state: int) -> void:
	# Boat can ALWAYS move — no locking
	match new_state:
		0:  # IDLE
			boat.set_can_move(true)
			boat.set_speed_multiplier(1.0)
			boat.set_camera_active(true)
		1:  # SINKING
			boat.set_can_move(true)
			boat.set_speed_multiplier(GameConfig.BOAT_SINKING_SPEED_MULTIPLIER)
			boat.set_camera_active(false)
			# If player drops while counting, process remaining instantly
			_cancel_counting_and_process()


func _on_magnet_surface_reached(items: Array) -> void:
	# Record collected items in collection tracker
	for item in items:
		if is_instance_valid(item) and "tier_id" in item and "variant_index" in item:
			if item.tier_id != "":
				collection_tracker.record_item(item.tier_id, item.variant_index)
	# Start one-by-one counting animation (no economy.process_check)
	_start_counting(items)


func _on_timer_updated(_remaining: float) -> void:
	pass


func _on_timer_expired() -> void:
	_round_ending = true
	var state: int = magnet.get_state()
	if state == 1:  # SINKING
		magnet.force_reset()
	# Cancel any active counting and process remaining
	_cancel_counting_and_process()
	_show_round_end()


## Show the round end summary screen (guarded against double-show).
func _show_round_end() -> void:
	if round_end.visible:
		return
	collection_panel.hide_collection()
	shop.hide_shop()
	round_end.show_summary(round_stats)


## Called when player presses retry on the round end screen.
func _on_retry() -> void:
	_round_ending = false
	round_stats.reset()
	hud.reset_urgent()
	# Clear old metals and respawn
	for child in metal_container.get_children():
		child.queue_free()
	_spawn_metals()
	# Reset round timer
	round_timer.reset()


## Show upgrade shop (manual only — player clicks icon).
func _show_shop() -> void:
	shop.show_shop(economy)


## Called when player closes the shop.
func _on_shop_continue() -> void:
	_apply_upgrade_effects()


## Sync upgrade effects from economy to game objects.
func _apply_upgrade_effects() -> void:
	magnet.max_attach_count = _base_attach_count + int(economy.get_upgrade_effect("magnet_power"))
	hud.setup(magnet.max_attach_count)

	magnet.base_retrieve_speed = _base_retrieve_speed * (1.0 + economy.get_upgrade_effect("retrieve_speed"))
	boat.base_speed = _base_boat_speed * (1.0 + economy.get_upgrade_effect("boat_speed"))
	magnet.steering_power = _base_steering_power * (1.0 + economy.get_upgrade_effect("steering"))
