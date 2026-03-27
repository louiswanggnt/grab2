extends Area2D

## Player-controlled magnet with 4-state cycle.
##
## State flow (per GDD):
##   IDLE → SINKING → RETRIEVING → CHECK → IDLE
##
## IDLE:       Magnet at mount_position. Player moves boat. Tap to drop.
## SINKING:    Gravity pulls down. Swipe steers X. Area2D catches items.
## RETRIEVING: Hold triggers upward pull. Weight slows retrieval.
## CHECK:      Reached surface. Items exchanged. Auto-returns to IDLE.

# ---------------------------------------------------------------------------
# Enums
# ---------------------------------------------------------------------------

enum State { IDLE, SINKING, RETRIEVING, CHECK }

const _VALID_TRANSITIONS: Dictionary = {
	State.IDLE: [State.SINKING],
	State.SINKING: [State.RETRIEVING],
	State.RETRIEVING: [State.CHECK],
	State.CHECK: [State.IDLE],
}

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

signal state_changed(old_state: State, new_state: State)
signal item_contacted(item: Node2D)
signal surface_reached(attached_items: Array)
signal check_completed()

# ---------------------------------------------------------------------------
# Exports
# ---------------------------------------------------------------------------

@export_group("Physics")
@export_range(300.0, 1000.0, 10.0) var sink_gravity: float = 600.0
@export_range(300.0, 800.0, 10.0) var max_sink_speed: float = 500.0
@export_range(200.0, 500.0, 10.0) var base_retrieve_speed: float = 300.0
@export_range(50.0, 300.0, 10.0) var steering_power: float = 150.0
@export_range(0.5, 0.95, 0.01) var steering_damping: float = 0.85
@export_range(0.05, 0.3, 0.01) var weight_drag_factor: float = 0.15

@export_group("Depth")
@export_range(1500.0, 3000.0, 50.0) var max_depth: float = 2000.0
@export_range(50.0, 200.0, 10.0) var min_sink_distance: float = 100.0

@export_group("Attachment")
@export_range(1, 10, 1) var max_attach_count: int = 3

@export_group("Scene Bounds")
@export var surface_y: float = 100.0
@export var scene_left: float = 0.0
@export var scene_right: float = 720.0

@export_group("References")
@export var mount_position: Vector2 = Vector2(0.0, 0.0)
@export var round_timer: Node

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

var _current_state: State = State.IDLE
var _velocity: Vector2 = Vector2.ZERO
var _attached_items: Array = []
var _current_retrieve_speed: float = 0.0
var _check_timer: SceneTreeTimer = null

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
	set_physics_process(false)
	_camera.enabled = false

	# Connect input signals
	TouchInputManager.tap_performed.connect(_on_tap_performed)
	TouchInputManager.hold_started.connect(_on_hold_started)
	TouchInputManager.swipe_updated.connect(_on_swipe_updated)

	# Connect overlap for item pickup (RigidBody2D metals)
	body_entered.connect(_on_body_entered)

	# Try loading real sprite
	var sprite_path: String = "res://assets/sprites/magnet/magnet.png"
	if ResourceLoader.exists(sprite_path):
		$Sprite2D.texture = load(sprite_path)
		$Sprite2D.modulate = Color.WHITE


func _physics_process(delta: float) -> void:
	match _current_state:
		State.SINKING:
			_process_sinking(delta)
		State.RETRIEVING:
			_process_retrieving(delta)

	# Update rope visual (line from magnet up toward boat)
	if _rope:
		_rope.set_point_position(1, Vector2(0, -(position.y - mount_position.y)))


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

func get_state() -> State:
	return _current_state


func get_attached_items() -> Array:
	return _attached_items.duplicate()


func force_reset() -> void:
	_detach_all_items()
	_velocity = Vector2.ZERO
	position = mount_position
	_current_state = State.IDLE
	_camera.enabled = false
	set_physics_process(false)


# ---------------------------------------------------------------------------
# State processing
# ---------------------------------------------------------------------------

func _process_sinking(delta: float) -> void:
	# Gravity acceleration with terminal velocity
	_velocity.y = minf(_velocity.y + sink_gravity * delta, max_sink_speed)

	# X-axis steering via swipe (applied in _on_swipe_updated)
	_velocity.x *= steering_damping

	# Apply movement
	position.x = clampf(position.x + _velocity.x * delta, scene_left, scene_right)
	position.y += _velocity.y * delta

	# Auto-retrieve at max depth
	if position.y >= surface_y + max_depth:
		_transition_to(State.RETRIEVING)


func _process_retrieving(delta: float) -> void:
	# Steering still works during retrieval
	_velocity.x *= steering_damping
	position.x = clampf(position.x + _velocity.x * delta, scene_left, scene_right)

	# Upward movement
	position.y -= _current_retrieve_speed * delta

	# Reached surface → CHECK
	if position.y <= surface_y:
		position.y = surface_y
		_transition_to(State.CHECK)


# ---------------------------------------------------------------------------
# State transitions
# ---------------------------------------------------------------------------

func _transition_to(new_state: State) -> void:
	if not _is_valid(new_state):
		push_warning("MagnetStateMachine: invalid %s -> %s" % [
			State.keys()[_current_state], State.keys()[new_state]])
		return

	var old: State = _current_state
	_exit_state(old)
	_current_state = new_state
	_enter_state(new_state)
	state_changed.emit(old, new_state)


func _is_valid(new_state: State) -> bool:
	var allowed: Array = _VALID_TRANSITIONS.get(_current_state, [])
	return allowed.has(new_state)


func _exit_state(state: State) -> void:
	match state:
		State.RETRIEVING:
			# Emit surface_reached with items before CHECK
			surface_reached.emit(_attached_items.duplicate())
		_:
			pass


func _enter_state(state: State) -> void:
	match state:
		State.IDLE:
			set_physics_process(false)
			_camera.enabled = false
			_velocity = Vector2.ZERO
			_detach_all_items()
			check_completed.emit()

		State.SINKING:
			set_physics_process(true)
			_camera.enabled = true
			_velocity = Vector2.ZERO
			# First drop starts the round timer
			if round_timer:
				round_timer.start_round()

		State.RETRIEVING:
			set_physics_process(true)
			# Calculate speed with weight penalty
			var total_weight: float = _get_total_weight()
			_current_retrieve_speed = base_retrieve_speed / (1.0 + total_weight * weight_drag_factor)
			# Force-retrieve on timer expired handled externally

		State.CHECK:
			set_physics_process(false)
			# Pause timer during CHECK — resumed by request_continue()
			if round_timer:
				round_timer.set_paused(true)
			# Start safety timeout (30s) — auto-continues if shop never closes
			_start_check_timeout()


## Called by external systems (shop, UI) to finish the CHECK phase.
## Also triggered automatically after 30 s if nobody calls it.
func request_continue() -> void:
	if _current_state != State.CHECK:
		return
	_cancel_check_timeout()
	_complete_check()


func _start_check_timeout() -> void:
	_check_timer = get_tree().create_timer(30.0)
	_check_timer.timeout.connect(request_continue, CONNECT_ONE_SHOT)


func _cancel_check_timeout() -> void:
	if _check_timer and _check_timer.timeout.is_connected(request_continue):
		_check_timer.timeout.disconnect(request_continue)
	_check_timer = null


func _complete_check() -> void:
	# Resume timer
	if round_timer:
		round_timer.set_paused(false)
	# Teleport back to mount
	position = mount_position
	_transition_to(State.IDLE)


# ---------------------------------------------------------------------------
# Item attachment
# ---------------------------------------------------------------------------

func _on_body_entered(body: Node2D) -> void:
	if _current_state != State.SINKING:
		return
	if not body.is_in_group("metal"):
		return
	if _attached_items.size() >= max_attach_count:
		return
	if body in _attached_items:
		return

	_attached_items.append(body)
	item_contacted.emit(body)
	call_deferred("_attach_item_deferred", body)


func _attach_item_deferred(item: Node2D) -> void:
	if not is_instance_valid(item):
		return
	# Freeze the RigidBody2D so it stops simulating physics
	if item is RigidBody2D:
		item.freeze = true
	if item.get_parent():
		item.get_parent().remove_child(item)
	if _catch_point:
		_catch_point.add_child(item)
		# Stack items below the magnet
		var idx: int = _attached_items.find(item)
		item.position = Vector2(0, idx * 25.0)
		item.rotation = 0.0


func _detach_all_items() -> void:
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
	# Tap while IDLE → start sinking (drop magnet)
	if _current_state == State.IDLE:
		_transition_to(State.SINKING)


func _on_hold_started(_hold_position: Vector2) -> void:
	# Hold while SINKING → start retrieving
	if _current_state == State.SINKING:
		# Guard: must have sunk at least min_sink_distance
		if position.y > surface_y + min_sink_distance:
			_transition_to(State.RETRIEVING)


func _on_swipe_updated(delta_x: float) -> void:
	# Steering only during SINKING or RETRIEVING
	if _current_state == State.SINKING or _current_state == State.RETRIEVING:
		_velocity.x += delta_x * steering_power
