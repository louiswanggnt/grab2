extends Area2D

## Player-controlled magnet with simplified state cycle.
##
## State flow:
##   IDLE → SINKING → IDLE
##
## IDLE:    Magnet at mount_position. Player moves boat. Tap to drop.
## SINKING: Gravity pulls down. Hold = pull up. Release = sink again.
##          Area2D catches items on contact.
##          Reaching surface with items → emits surface_reached → IDLE.
##          Main.gd handles item counting animation.

# ---------------------------------------------------------------------------
# Enums
# ---------------------------------------------------------------------------

enum State { IDLE, SINKING, CHECK }

const _VALID_TRANSITIONS: Dictionary = {
	State.IDLE: [State.SINKING],
	State.SINKING: [State.IDLE],
	State.CHECK: [State.IDLE],
}

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

signal state_changed(old_state: State, new_state: State)
signal item_contacted(item: Node2D)
signal surface_reached(attached_items: Array)

# ---------------------------------------------------------------------------
# Exports
# ---------------------------------------------------------------------------

## These read defaults from GameConfig but can be overridden per-instance via @export
@export_group("Physics")
var sink_gravity: float = 0.0
var max_sink_speed: float = 0.0
var base_retrieve_speed: float = 0.0
var steering_power: float = 0.0
var steering_damping: float = 0.0
var weight_drag_factor: float = 0.0
var max_depth: float = 0.0
var max_attach_count: int = 0

@export_group("Scene Bounds")
var surface_y: float = 0.0
var scene_left: float = 0.0
var scene_right: float = 0.0

@export_group("References")
@export var mount_position: Vector2 = Vector2(0.0, 0.0)
@export var round_timer: Node

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

var _current_state: State = State.IDLE
var _velocity: Vector2 = Vector2.ZERO
var _attached_items: Array = []
var _is_pulling: bool = false  # Hold screen = pull up
var _sinking_blocked: bool = false  # True = hit seabed or full+metal, no gravity until player pulls

# ---------------------------------------------------------------------------
# Child references
# ---------------------------------------------------------------------------

@onready var _catch_point: Marker2D = $CatchPoint
@onready var _rope: Line2D = $Rope
@onready var _camera: Camera2D = $Camera2D

# ---------------------------------------------------------------------------
# Built-in
# ---------------------------------------------------------------------------

func _ready() -> void:
	# Load defaults from GameConfig
	sink_gravity = GameConfig.MAGNET_SINK_GRAVITY
	max_sink_speed = GameConfig.MAGNET_MAX_SINK_SPEED
	base_retrieve_speed = GameConfig.MAGNET_BASE_RETRIEVE_SPEED
	steering_power = GameConfig.MAGNET_STEERING_POWER
	steering_damping = GameConfig.MAGNET_STEERING_DAMPING
	weight_drag_factor = GameConfig.MAGNET_WEIGHT_DRAG_FACTOR
	max_depth = GameConfig.MAX_DEPTH
	max_attach_count = GameConfig.MAGNET_MAX_ATTACH_COUNT
	surface_y = GameConfig.SURFACE_Y
	scene_left = GameConfig.SCENE_LEFT
	scene_right = GameConfig.SCENE_RIGHT

	set_physics_process(false)
	_camera.enabled = false

	# Connect input signals
	TouchInputManager.tap_performed.connect(_on_tap_performed)
	TouchInputManager.hold_started.connect(_on_hold_started)
	TouchInputManager.hold_released.connect(_on_hold_released)
	TouchInputManager.swipe_updated.connect(_on_swipe_updated)

	# Connect overlap for item pickup (RigidBody2D metals)
	body_entered.connect(_on_body_entered)

	# Try loading real sprite — show Sprite2D and hide ColorRect placeholder
	var sprite_path: String = "res://assets/sprites/magnet/magnet.png"
	if ResourceLoader.exists(sprite_path):
		$Sprite2D.texture = load(sprite_path)
		$Sprite2D.visible = true
		$ColorRect.visible = false


func _unhandled_input(event: InputEvent) -> void:
	# Right click to drop heaviest item
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			if _current_state == State.SINKING and not _attached_items.is_empty():
				drop_heaviest()


func _physics_process(delta: float) -> void:
	if _current_state == State.SINKING:
		_process_sinking(delta)

	# Update rope visual
	if _rope:
		_rope.set_point_position(1, Vector2(0, -(position.y - mount_position.y)))


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

func get_state() -> State:
	return _current_state


func is_pulling() -> bool:
	return _is_pulling


func get_attached_items() -> Array:
	return _attached_items.duplicate()


func drop_heaviest() -> void:
	if _attached_items.is_empty():
		return
	# Find the heaviest item
	var heaviest: Node2D = null
	var max_weight: float = -1.0
	for item in _attached_items:
		if not is_instance_valid(item):
			continue
		var w: float = item.weight if "weight" in item else 1.0
		if w > max_weight:
			max_weight = w
			heaviest = item
	if heaviest == null:
		return
	# Remove from list
	_attached_items.erase(heaviest)
	# Detach from catch point and drop into the world
	if heaviest.get_parent():
		heaviest.get_parent().remove_child(heaviest)
	# Add back to scene at current magnet position
	get_parent().add_child(heaviest)
	heaviest.global_position = global_position + Vector2(0, 30)
	if heaviest is RigidBody2D:
		heaviest.freeze = true  # Stay frozen where dropped
	# Reposition remaining items
	for i in range(_attached_items.size()):
		var item: Node2D = _attached_items[i]
		if is_instance_valid(item):
			item.position = Vector2(0, i * 25.0)


func force_reset() -> void:
	_free_all_items()
	_velocity = Vector2.ZERO
	_is_pulling = false
	_sinking_blocked = false
	position = mount_position
	_current_state = State.IDLE
	_camera.enabled = false
	set_physics_process(false)


## Clear the internal attached items list without freeing nodes.
## Call this after Main.gd finishes counting animation.
func clear_attached_list() -> void:
	_attached_items.clear()


# ---------------------------------------------------------------------------
# State processing
# ---------------------------------------------------------------------------

func _process_sinking(delta: float) -> void:
	if _is_pulling:
		# Player is pulling — clear blocked flag, move upward
		_sinking_blocked = false
		var total_weight: float = _get_total_weight()
		var pull_speed: float = base_retrieve_speed / (1.0 + total_weight * weight_drag_factor)
		_velocity.y = -pull_speed
	elif _sinking_blocked:
		# Hit seabed or full+metal — stay put until player pulls
		_velocity = Vector2.ZERO
		return
	else:
		# Sink with gravity
		_velocity.y = minf(_velocity.y + sink_gravity * delta, max_sink_speed)

	# X-axis steering
	_velocity.x *= steering_damping

	# Apply movement
	position.x = clampf(position.x + _velocity.x * delta, scene_left, scene_right)
	position.y += _velocity.y * delta

	# Seabed — position-based clamp
	if position.y >= GameConfig.SEABED_Y:
		position.y = GameConfig.SEABED_Y
		_velocity = Vector2.ZERO
		_sinking_blocked = true

	# Max depth safety clamp
	if position.y >= surface_y + max_depth:
		position.y = surface_y + max_depth
		_velocity = Vector2.ZERO
		_sinking_blocked = true

	# Reached surface while pulling → IDLE (Main.gd handles counting animation)
	if _is_pulling and position.y <= surface_y:
		position.y = surface_y
		surface_reached.emit(_attached_items.duplicate())
		_transition_to(State.IDLE)


# ---------------------------------------------------------------------------
# State transitions
# ---------------------------------------------------------------------------

func _transition_to(new_state: State) -> void:
	if not _is_valid(new_state):
		push_warning("MagnetStateMachine: invalid %s -> %s" % [
			State.keys()[_current_state], State.keys()[new_state]])
		return

	var old: State = _current_state
	_current_state = new_state
	_enter_state(new_state)
	state_changed.emit(old, new_state)


func _is_valid(new_state: State) -> bool:
	var allowed: Array = _VALID_TRANSITIONS.get(_current_state, [])
	return allowed.has(new_state)


func _enter_state(state: State) -> void:
	match state:
		State.IDLE:
			set_physics_process(false)
			_camera.enabled = false
			_velocity = Vector2.ZERO
			_is_pulling = false
			_sinking_blocked = false
			# Items are NOT freed here — Main.gd handles counting animation

		State.SINKING:
			set_physics_process(true)
			_camera.enabled = true
			_velocity = Vector2.ZERO
			_is_pulling = false
			_sinking_blocked = false
			# First drop starts the round timer
			if round_timer:
				round_timer.start_round()


# ---------------------------------------------------------------------------
# Item attachment
# ---------------------------------------------------------------------------

func _on_body_entered(body: Node2D) -> void:
	if _current_state != State.SINKING:
		return

	if not body.is_in_group("metal"):
		return

	# Already at max capacity + touching metal → clamp position, block sinking
	if _attached_items.size() >= max_attach_count:
		_velocity = Vector2.ZERO
		_sinking_blocked = true
		return

	if body in _attached_items:
		return

	_attached_items.append(body)
	item_contacted.emit(body)
	call_deferred("_attach_item_deferred", body)


func _attach_item_deferred(item: Node2D) -> void:
	if not is_instance_valid(item):
		return
	if item is RigidBody2D:
		item.freeze = true
	if item.get_parent():
		item.get_parent().remove_child(item)
	if _catch_point:
		_catch_point.add_child(item)
		var idx: int = _attached_items.find(item)
		item.position = Vector2(0, idx * GameConfig.MAGNET_ATTACH_SPACING)
		item.rotation = 0.0


func _free_all_items() -> void:
	for item in _attached_items:
		if is_instance_valid(item):
			item.queue_free()
	_attached_items.clear()


func _get_total_weight() -> float:
	var total: float = 0.0
	for item in _attached_items:
		if is_instance_valid(item) and "weight" in item:
			total += item.weight
		else:
			total += 1.0
	return total


# ---------------------------------------------------------------------------
# Input callbacks
# ---------------------------------------------------------------------------

func _on_tap_performed(_tap_position: Vector2) -> void:
	if _current_state == State.IDLE:
		_transition_to(State.SINKING)


func _on_hold_started(_hold_position: Vector2) -> void:
	if _current_state == State.SINKING:
		_is_pulling = true
		_velocity.y = 0.0  # Reset downward velocity immediately


func _on_hold_released(_release_position: Vector2) -> void:
	if _current_state == State.SINKING:
		_is_pulling = false
		_velocity.y = 0.0  # Reset so gravity starts fresh


func _on_swipe_updated(delta_x: float) -> void:
	if _current_state == State.SINKING:
		_velocity.x += delta_x * steering_power
