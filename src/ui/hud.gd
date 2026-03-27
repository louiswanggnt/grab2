extends Control

## In-game HUD: timer, money, and attachment counter.

# ---------------------------------------------------------------------------
# Child references
# ---------------------------------------------------------------------------

@onready var _money_label: Label = $TopBar/MoneyLabel
@onready var _timer_label: Label = $TopBar/TimerLabel
@onready var _attach_label: Label = $AttachmentCounter

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

var _is_urgent: bool = false
var _attached_count: int = 0
var _max_attach: int = 0

# ---------------------------------------------------------------------------
# Built-in
# ---------------------------------------------------------------------------

func _process(_delta: float) -> void:
	if _is_urgent:
		var pulse: float = 1.0 + 0.1 * absf(sin(Time.get_ticks_msec() / 1000.0 * PI))
		_timer_label.scale = Vector2(pulse, pulse)


# ---------------------------------------------------------------------------
# Public API (called by Main.gd signal wiring)
# ---------------------------------------------------------------------------

## Initialize HUD with magnet capacity. Call again when max changes (upgrades).
func setup(max_attach_count: int) -> void:
	_max_attach = max_attach_count
	_update_attach_display()


## Update timer display from RoundTimer.time_updated signal.
func on_time_updated(remaining: float) -> void:
	var minutes: int = int(remaining) / 60
	var seconds: int = int(remaining) % 60
	_timer_label.text = "%02d:%02d" % [minutes, seconds]


## Switch timer to urgent visual (red + pulse). Called by urgent_mode_entered.
func on_urgent_mode() -> void:
	_is_urgent = true
	_timer_label.pivot_offset = _timer_label.size / 2.0
	_timer_label.add_theme_color_override("font_color", Color("#FF4444"))


## Update money display. Called by economy.money_changed.
func on_money_changed(new_total: int) -> void:
	_money_label.text = "$%d" % new_total


## Increment attachment count. Called by magnet.item_contacted.
func on_item_attached(_item: Node2D) -> void:
	_attached_count += 1
	_update_attach_display()


## React to magnet state changes. Resets counter on IDLE, shows only during SINKING.
func on_magnet_state_changed(_old_state: int, new_state: int) -> void:
	# Show counter only while diving (SINKING=1)
	_attach_label.visible = new_state == 1
	if new_state == 0:  # State.IDLE
		_attached_count = 0
		_update_attach_display()


## Reset urgent visual to normal state.
func reset_urgent() -> void:
	_is_urgent = false
	_timer_label.scale = Vector2.ONE
	_timer_label.add_theme_color_override("font_color", Color.WHITE)


# ---------------------------------------------------------------------------
# Private
# ---------------------------------------------------------------------------

func _update_attach_display() -> void:
	_attach_label.text = "%d / %d" % [_attached_count, _max_attach]
	if _attached_count >= _max_attach:
		_attach_label.add_theme_color_override("font_color", Color("#FF6600"))
	else:
		_attach_label.add_theme_color_override("font_color", Color.WHITE)
