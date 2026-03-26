extends Node2D

## Game orchestrator. Wires magnet, boat, economy, and timer together.

@onready var metal_container: Node2D = $MetalContainer
@onready var money_label: Label = $UI/MoneyLabel
@onready var info_label: Label = $UI/InfoLabel
@onready var boat: CharacterBody2D = $Boat

var magnet_scene: PackedScene = preload("res://Magnet.tscn")
var metal_scene: PackedScene = preload("res://MetalObject.tscn")
var fish_scene: PackedScene = preload("res://Fish.tscn")

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
	round_timer.round_duration = GameConfig.ROUND_DURATION
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

	# Position seabed from GameConfig
	var seabed: StaticBody2D = $Seabed
	seabed.position.y = GameConfig.SEABED_Y

	# Spawn metal objects and decorative fish
	_spawn_metals()
	_spawn_fish()
	_update_ui()


func _process(_delta: float) -> void:
	if not magnet:
		return
	var mount_pos: Vector2 = boat.get_node("MagnetMount").global_position
	magnet.mount_position = mount_pos

	if magnet.get_state() == 0:  # IDLE — stick to boat
		magnet.position = mount_pos
	elif magnet.get_state() == 1:  # SINKING — sync X with boat
		magnet.position.x = mount_pos.x


func _spawn_metals() -> void:
	for tier in GameConfig.METAL_TIERS:
		var w: float = tier[0]
		var v: int = tier[1]
		var s: float = tier[2]
		var count: int = tier[3]
		for i in range(count):
			var metal: RigidBody2D = metal_scene.instantiate()
			metal_container.add_child(metal)
			metal.set_metal_properties(w, v, s)
			metal.freeze = true
			metal.position = Vector2(
				randf_range(GameConfig.METAL_SPAWN_X_MIN, GameConfig.METAL_SPAWN_X_MAX),
				GameConfig.METAL_SEABED_TOP_Y - s / 2.0 - randf_range(0, s * 2.0)
			)


func _spawn_fish() -> void:
	for i in range(GameConfig.FISH_COUNT):
		var fish: Node2D = fish_scene.instantiate()
		# Set position BEFORE add_child so _ready() picks up correct _base_y
		fish.position = Vector2(
			randf_range(GameConfig.FISH_SPAWN_X_MIN, GameConfig.FISH_SPAWN_X_MAX),
			randf_range(GameConfig.FISH_SPAWN_Y_MIN, GameConfig.FISH_SPAWN_Y_MAX)
		)
		var s: float = randf_range(GameConfig.FISH_SCALE_MIN, GameConfig.FISH_SCALE_MAX)
		fish.scale *= s
		add_child(fish)


func _on_magnet_state_changed(_old_state: int, new_state: int) -> void:
	# IDLE (0): full speed, boat camera
	# SINKING (1): half speed, magnet camera
	# CHECK (2): locked, magnet camera
	match new_state:
		0:  # IDLE
			boat.set_can_move(true)
			boat.set_speed_multiplier(1.0)
			boat.set_camera_active(true)
		1:  # SINKING
			boat.set_can_move(true)
			boat.set_speed_multiplier(GameConfig.BOAT_SINKING_SPEED_MULTIPLIER)
			boat.set_camera_active(false)
		_:  # CHECK
			boat.set_can_move(false)
			boat.set_camera_active(false)


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
