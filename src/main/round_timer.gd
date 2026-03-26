class_name RoundTimer
extends Node

## Manages the 4-minute per-round countdown.
##
## State machine: WAITING → RUNNING ↔ PAUSED → EXPIRED
##
## Typical usage:
##   # Wire up from the scene that owns the magnet state machine:
##   round_timer.start_round()          # called when first magnet drop occurs
##   round_timer.set_paused(true/false) # called on CHECK state enter/exit
##
## The timer does not know about the magnet state machine directly.
## The owner scene is responsible for calling these methods at the right time.

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

## Emitted every frame while RUNNING. `remaining` is seconds left.
signal time_updated(remaining: float)
## Emitted once when remaining time first drops to or below urgent_threshold.
signal urgent_mode_entered()
## Emitted once when the countdown reaches zero.
signal time_expired()

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

## Total round duration in seconds (GDD default: 240 = 4 minutes).
@export_range(60.0, 600.0, 10.0) var round_duration: float = 240.0
## Remaining seconds at which urgent mode activates (GDD default: 30).
@export_range(5.0, 120.0, 5.0) var urgent_threshold: float = 30.0
## Whether the timer pauses during CHECK state.
@export var pause_during_check: bool = true

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

enum TimerState { WAITING, RUNNING, PAUSED, EXPIRED }

var _state: TimerState = TimerState.WAITING
var _elapsed_active_time: float = 0.0
var _urgent_mode_fired: bool = false


# ---------------------------------------------------------------------------
# Built-in virtual methods
# ---------------------------------------------------------------------------

func _ready() -> void:
	set_process(false)


func _process(delta: float) -> void:
	if _state != TimerState.RUNNING:
		return

	_elapsed_active_time += delta
	var remaining: float = get_time_remaining()
	time_updated.emit(remaining)

	if not _urgent_mode_fired and remaining <= urgent_threshold:
		_urgent_mode_fired = true
		urgent_mode_entered.emit()

	if remaining <= 0.0:
		_transition_to(TimerState.EXPIRED)
		time_expired.emit()


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Call this when the player releases the magnet for the first time.
## Has no effect if the timer has already started or has expired.
func start_round() -> void:
	if _state != TimerState.WAITING:
		return
	_transition_to(TimerState.RUNNING)


## Pause or resume the timer (e.g. when entering/leaving CHECK state).
## Has no effect if the timer has not started or has already expired.
func set_paused(paused: bool) -> void:
	if not pause_during_check:
		return
	if _state == TimerState.EXPIRED or _state == TimerState.WAITING:
		return

	if paused and _state == TimerState.RUNNING:
		_transition_to(TimerState.PAUSED)
	elif not paused and _state == TimerState.PAUSED:
		_transition_to(TimerState.RUNNING)


## Returns seconds remaining. Never goes below 0.
func get_time_remaining() -> float:
	return maxf(round_duration - _elapsed_active_time, 0.0)


## Returns true once the last 30 s threshold has been crossed.
func is_urgent() -> bool:
	return _urgent_mode_fired


## Returns the current state enum value.
func get_state() -> TimerState:
	return _state


## Resets the timer to WAITING for a new round.
func reset() -> void:
	_elapsed_active_time = 0.0
	_urgent_mode_fired = false
	_transition_to(TimerState.WAITING)


# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

func _transition_to(new_state: TimerState) -> void:
	_state = new_state
	# Only run _process while the timer is ticking.
	set_process(_state == TimerState.RUNNING)
