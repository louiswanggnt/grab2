extends Control

## Round end summary screen with stats and replay button.

signal retry_pressed()

# ---------------------------------------------------------------------------
# Child references
# ---------------------------------------------------------------------------

@onready var _earnings_label: Label = $Content/EarningsLabel
@onready var _dive_count_label: Label = $Content/DiveCountLabel
@onready var _best_dive_label: Label = $Content/BestDiveLabel
@onready var _rating_label: Label = $Content/RatingLabel
@onready var _retry_btn: Button = $Content/RetryButton

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

var _target_earnings: int = 0

# ---------------------------------------------------------------------------
# Built-in
# ---------------------------------------------------------------------------

func _ready() -> void:
	_retry_btn.pressed.connect(_on_retry_pressed)
	visible = false


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Show round end screen with stats from RoundStats.
func show_summary(stats: Node) -> void:
	_dive_count_label.text = "%d 次下潛" % stats.dive_count
	_best_dive_label.text = "最佳下潛：$%d" % stats.best_dive_earnings
	_rating_label.text = stats.get_rating()
	_target_earnings = stats.total_earnings
	_earnings_label.text = "+$0"
	modulate = Color(1, 1, 1, 0)
	visible = true
	var fade_tween: Tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 1.0, 0.3)
	_animate_earnings()


## Hide the screen.
func hide_summary() -> void:
	visible = false


# ---------------------------------------------------------------------------
# Animation
# ---------------------------------------------------------------------------

func _animate_earnings() -> void:
	var tween: Tween = create_tween()
	tween.tween_method(_update_earnings_display, 0, _target_earnings, 0.8)\
		.set_trans(Tween.TRANS_EXPO)\
		.set_ease(Tween.EASE_OUT)


func _update_earnings_display(value: int) -> void:
	_earnings_label.text = "+$%d" % value


# ---------------------------------------------------------------------------
# Callbacks
# ---------------------------------------------------------------------------

func _on_retry_pressed() -> void:
	hide_summary()
	retry_pressed.emit()
