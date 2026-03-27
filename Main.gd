extends Node2D

## Game orchestrator. Wires magnet, boat, economy, and timer together.

@onready var metal_container: Node2D = $MetalContainer
@onready var boat: CharacterBody2D = $Boat

var magnet_scene: PackedScene = preload("res://Magnet.tscn")
var metal_scene: PackedScene = preload("res://MetalObject.tscn")
var hud_scene: PackedScene = preload("res://src/ui/hud.tscn")
var shop_scene: PackedScene = preload("res://src/ui/shop_panel.tscn")
var round_end_scene: PackedScene = preload("res://src/ui/round_end_screen.tscn")

var magnet: Area2D = null
var economy: Node = null
var round_timer: Node = null
var round_stats: Node = null
var hud: Control = null
var shop: Control = null
var round_end: Control = null
var _round_ending: bool = false
var _base_attach_count: int = 0
var _base_retrieve_speed: float = 0.0
var _base_boat_speed: float = 0.0
var _base_steering_power: float = 0.0

func _ready() -> void:
	# Create economy system
	economy = load("res://src/economy/economy_system.gd").new()
	economy.name = "EconomySystem"
	add_child(economy)

	# Create round timer
	round_timer = load("res://src/main/round_timer.gd").new()
	round_timer.name = "RoundTimer"
	round_timer.round_duration = 240.0
	add_child(round_timer)

	# Create round stats tracker
	round_stats = load("res://src/main/round_stats.gd").new()
	round_stats.name = "RoundStats"
	add_child(round_stats)

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

	# Wire signals
	magnet.state_changed.connect(_on_magnet_state_changed)
	magnet.surface_reached.connect(_on_magnet_surface_reached)
	magnet.check_completed.connect(_on_magnet_check_completed)
	economy.check_completed.connect(_on_economy_check_completed)
	round_timer.time_updated.connect(_on_timer_updated)
	round_timer.time_expired.connect(_on_timer_expired)

	# Wire HUD signals
	round_timer.time_updated.connect(hud.on_time_updated)
	round_timer.urgent_mode_entered.connect(hud.on_urgent_mode)
	economy.money_changed.connect(hud.on_money_changed)
	magnet.item_contacted.connect(hud.on_item_attached)
	magnet.state_changed.connect(hud.on_magnet_state_changed)

	# Spawn metal objects
	_spawn_metals()


func _process(_delta: float) -> void:
	# Keep magnet mount_position synced with boat while IDLE
	if magnet and magnet.get_state() == magnet.State.IDLE:
		var mount_pos: Vector2 = boat.get_node("MagnetMount").global_position
		magnet.position = mount_pos
		magnet.mount_position = mount_pos


func _spawn_metals() -> void:
	# Weight tiers: [weight, value, size, spawn_y_min, spawn_y_max, count]
	# Lighter metals near surface, heavier metals deeper
	var tiers: Array = [
		[1.0, 5, 20.0, 300, 600, 10],     # Light — shallow water
		[2.0, 15, 28.0, 600, 1000, 8],     # Medium — mid depth
		[3.0, 30, 36.0, 1000, 1400, 5],    # Heavy — deep
		[5.0, 60, 48.0, 1400, 1700, 2],    # Very heavy — bottom
	]

	for tier in tiers:
		var w: float = tier[0]
		var v: int = tier[1]
		var s: float = tier[2]
		var y_min: float = tier[3]
		var y_max: float = tier[4]
		var count: int = tier[5]
		for i in range(count):
			var metal: RigidBody2D = metal_scene.instantiate()
			metal_container.add_child(metal)
			metal.set_metal_properties(w, v, s)
			metal.position = Vector2(
				randf_range(50, 670),
				randf_range(y_min, y_max)
			)


func _on_magnet_state_changed(_old_state: int, new_state: int) -> void:
	boat.set_can_move(new_state == magnet.State.IDLE)
	boat.set_camera_active(new_state == magnet.State.IDLE)
	# Show shop during CHECK
	if new_state == magnet.State.CHECK:
		_show_shop()


func _on_magnet_surface_reached(items: Array) -> void:
	economy.process_check(items)


func _on_magnet_check_completed() -> void:
	pass


func _on_economy_check_completed(earnings: int) -> void:
	round_stats.record_dive(earnings)
	# Show round end after stats are recorded (not before)
	if _round_ending:
		_show_round_end()


func _on_timer_updated(_remaining: float) -> void:
	pass


func _on_timer_expired() -> void:
	_round_ending = true
	var state: int = magnet.get_state()
	if state == magnet.State.CHECK:
		# Economy already processed — force close shop and show round end
		shop.hide_shop()
		magnet.request_continue()
		_show_round_end()
	elif state != magnet.State.IDLE:
		magnet.force_reset()
		_show_round_end()
	else:
		_show_round_end()


## Show the round end summary screen (guarded against double-show).
func _show_round_end() -> void:
	if round_end.visible:
		return
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


## Show upgrade shop during CHECK state.
func _show_shop() -> void:
	shop.show_shop(economy)


## Called when player closes the shop.
func _on_shop_continue() -> void:
	_apply_upgrade_effects()
	if not _round_ending:
		magnet.request_continue()


## Sync upgrade effects from economy to game objects.
func _apply_upgrade_effects() -> void:
	magnet.max_attach_count = _base_attach_count + int(economy.get_upgrade_effect("magnet_power"))
	hud.setup(magnet.max_attach_count)

	magnet.base_retrieve_speed = _base_retrieve_speed * (1.0 + economy.get_upgrade_effect("retrieve_speed"))
	boat.base_speed = _base_boat_speed * (1.0 + economy.get_upgrade_effect("boat_speed"))
	magnet.steering_power = _base_steering_power * (1.0 + economy.get_upgrade_effect("steering"))


