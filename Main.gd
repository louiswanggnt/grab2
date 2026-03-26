extends Node2D

## Game orchestrator. Wires magnet, boat, economy, and timer together.

@onready var metal_container: Node2D = $MetalContainer
@onready var money_label: Label = $UI/MoneyLabel
@onready var info_label: Label = $UI/InfoLabel
@onready var boat: CharacterBody2D = $Boat

var magnet_scene: PackedScene = preload("res://Magnet.tscn")
var metal_scene: PackedScene = preload("res://MetalObject.tscn")

var magnet: Area2D = null
var economy: Node = null
var round_timer: Node = null

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

	# Instantiate magnet at boat's mount point
	magnet = magnet_scene.instantiate()
	add_child(magnet)
	var mount_pos: Vector2 = boat.get_node("MagnetMount").global_position
	magnet.position = mount_pos
	magnet.mount_position = mount_pos
	magnet.surface_y = mount_pos.y
	magnet.round_timer = round_timer

	# Wire signals
	magnet.state_changed.connect(_on_magnet_state_changed)
	magnet.surface_reached.connect(_on_magnet_surface_reached)
	magnet.check_completed.connect(_on_magnet_check_completed)
	economy.money_changed.connect(_on_money_changed)
	economy.check_completed.connect(_on_check_completed)
	round_timer.time_updated.connect(_on_timer_updated)
	round_timer.time_expired.connect(_on_timer_expired)

	# Spawn metal objects
	_spawn_metals()
	_update_ui()


func _process(_delta: float) -> void:
	# Keep magnet mount_position synced with boat while IDLE
	if magnet and magnet.get_state() == 0:  # State.IDLE = 0
		var mount_pos: Vector2 = boat.get_node("MagnetMount").global_position
		magnet.position = mount_pos
		magnet.mount_position = mount_pos


func _spawn_metals() -> void:
	# Weight tiers: [weight, value, size, count]
	var tiers: Array = [
		[1.0, 5, 20.0, 10],    # Light — small, low value
		[2.0, 15, 28.0, 8],    # Medium
		[3.0, 30, 36.0, 5],    # Heavy
		[5.0, 60, 48.0, 2],    # Very heavy — big, high value
	]

	for tier in tiers:
		var w: float = tier[0]
		var v: int = tier[1]
		var s: float = tier[2]
		var count: int = tier[3]
		for i in range(count):
			var metal: RigidBody2D = metal_scene.instantiate()
			metal_container.add_child(metal)
			metal.set_metal_properties(w, v, s)
			# Spawn above seabed so they fall and stack
			metal.position = Vector2(
				randf_range(50, 670),
				randf_range(1400, 1700)
			)


func _on_magnet_state_changed(_old_state: int, new_state: int) -> void:
	# Lock boat when magnet is not IDLE (0)
	boat.set_can_move(new_state == 0)
	# Camera switching
	boat.set_camera_active(new_state == 0)


func _on_magnet_surface_reached(items: Array) -> void:
	economy.process_check(items)


func _on_magnet_check_completed() -> void:
	_update_ui()


func _on_money_changed(new_total: int) -> void:
	money_label.text = "Money: $%d" % new_total


func _on_check_completed(earnings: int) -> void:
	if earnings > 0:
		info_label.text = "+$%d earned!" % earnings
	else:
		info_label.text = "Nothing caught..."


func _on_timer_updated(_remaining: float) -> void:
	pass


func _on_timer_expired() -> void:
	if magnet.get_state() != 0:  # Not IDLE
		magnet.force_reset()
	info_label.text = "Round over!"


func _update_ui() -> void:
	money_label.text = "Money: $%d" % economy.get_money()
	info_label.text = "Click to drop | Hold to retrieve"
