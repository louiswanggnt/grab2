extends Node

## Autoload singleton — detects touch gestures and keyboard/mouse input
## and emits game-action signals. Does NOT manage any state machine.
##
## Consumers connect to the signals they care about:
##   TouchInputManager.tap_performed.connect(_on_tap)
##   TouchInputManager.move_direction_changed.connect(_on_move_direction)
##
## PC primary (keyboard + mouse); touch is the secondary path.

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

## Fired when a tap (short press under tap_max_duration ms) is recognised.
signal tap_performed(position: Vector2)
## Fired when a hold gesture reaches hold_min_duration ms.
signal hold_started(position: Vector2)
## Fired when a hold is released (finger/mouse up after hold_started).
signal hold_released(position: Vector2)
## Fired every frame while a horizontal swipe / mouse drag is active.
## delta_x is the horizontal delta in pixels since last frame.
signal swipe_updated(delta_x: float)
## Fired when the boat-movement direction changes.
## direction: -1 (left), 0 (stopped), 1 (right)
signal move_direction_changed(direction: float)

# ---------------------------------------------------------------------------
# Tuning parameters — expose to inspector via @export so designers can tweak
# ---------------------------------------------------------------------------

## Maximum press duration (seconds) that counts as a tap.
@export_range(0.05, 1.0, 0.01) var tap_max_duration: float = 0.2
## Maximum finger/cursor travel (px) still counted as a tap.
@export_range(1.0, 100.0, 1.0) var tap_max_distance: float = 20.0
## Minimum press duration (seconds) before hold_started fires.
@export_range(0.1, 1.0, 0.01) var hold_min_duration: float = 0.3
## Minimum horizontal travel (px) to register as a swipe.
@export_range(5.0, 200.0, 1.0) var swipe_min_distance: float = 30.0
## Multiplier applied to horizontal mouse/touch delta for magnet steering.
@export_range(0.05, 2.0, 0.05) var steering_sensitivity: float = 0.3

# ---------------------------------------------------------------------------
# Private state
# ---------------------------------------------------------------------------

## Whether a touch/mouse press is currently active.
var _is_pressing: bool = false
## World position where the current press began.
var _press_start_position: Vector2 = Vector2.ZERO
## Elapsed time (seconds) since the press began.
var _press_elapsed: float = 0.0
## Whether hold_started has already fired for the current press.
var _hold_fired: bool = false
## Whether the current press has been disqualified from being a tap.
var _tap_cancelled: bool = false
## Whether a horizontal swipe is currently active.
var _swipe_active: bool = false
## Tracked press position (works for both mouse and touch).
var _current_press_position: Vector2 = Vector2.ZERO
## Cursor position in the previous frame (for delta calculation).
var _prev_mouse_position: Vector2 = Vector2.ZERO
## Current boat move direction — cached to avoid spamming the signal.
var _current_move_direction: float = 0.0


# ---------------------------------------------------------------------------
# Built-in virtual methods
# ---------------------------------------------------------------------------

func _ready() -> void:
	_prev_mouse_position = get_viewport().get_mouse_position()


func _process(delta: float) -> void:
	_handle_keyboard_movement()
	_handle_mouse_swipe()

	if _is_pressing:
		_press_elapsed += delta
		_check_tap_distance()
		_check_hold_threshold()


func _input(event: InputEvent) -> void:
	# --- Mouse ---
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_begin_press(mb.position)
			else:
				_end_press(mb.position)

	# --- Touch ---
	elif event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event as InputEventScreenTouch
		# Only track the first finger (index 0).
		if touch.index == 0:
			if touch.pressed:
				_begin_press(touch.position)
			else:
				_end_press(touch.position)

	elif event is InputEventScreenDrag:
		var drag: InputEventScreenDrag = event as InputEventScreenDrag
		if drag.index == 0 and _is_pressing:
			_current_press_position = drag.position
			_process_swipe_delta(drag.relative.x)


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Returns the current move direction without waiting for the signal.
func get_move_direction() -> float:
	return _current_move_direction


# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

func _begin_press(position: Vector2) -> void:
	_is_pressing = true
	_press_start_position = position
	_current_press_position = position
	_press_elapsed = 0.0
	_hold_fired = false
	_tap_cancelled = false
	_swipe_active = false


func _end_press(position: Vector2) -> void:
	if not _is_pressing:
		return

	_is_pressing = false

	if _hold_fired:
		hold_released.emit(position)
		return

	# Determine tap: press was short and cursor stayed within tolerance.
	if not _tap_cancelled and _press_elapsed <= tap_max_duration:
		tap_performed.emit(position)


func _check_tap_distance() -> void:
	if _tap_cancelled:
		return
	if _press_start_position.distance_to(_current_press_position) > tap_max_distance:
		_tap_cancelled = true


func _check_hold_threshold() -> void:
	if _hold_fired or _tap_cancelled:
		return
	if _press_elapsed >= hold_min_duration:
		_hold_fired = true
		hold_started.emit(_press_start_position)


func _handle_keyboard_movement() -> void:
	var direction: float = 0.0
	if Input.is_action_pressed(&"move_left"):
		direction -= 1.0
	if Input.is_action_pressed(&"move_right"):
		direction += 1.0

	if direction != _current_move_direction:
		_current_move_direction = direction
		move_direction_changed.emit(_current_move_direction)


func _handle_mouse_swipe() -> void:
	var current_mouse: Vector2 = get_viewport().get_mouse_position()
	var mouse_delta_x: float = current_mouse.x - _prev_mouse_position.x
	_prev_mouse_position = current_mouse

	# Only emit swipe when mouse button is held (drag) and delta is meaningful.
	if _is_pressing and absf(mouse_delta_x) > 0.5:
		_current_press_position = current_mouse
		_process_swipe_delta(mouse_delta_x)


func _process_swipe_delta(raw_delta_x: float) -> void:
	var horizontal_movement: float = absf(raw_delta_x)

	if not _swipe_active and horizontal_movement >= swipe_min_distance:
		_swipe_active = true

	if _swipe_active:
		# Cancel tap once the player clearly starts sliding.
		if horizontal_movement >= swipe_min_distance:
			_tap_cancelled = true
		swipe_updated.emit(raw_delta_x * steering_sensitivity)
