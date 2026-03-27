extends CharacterBody2D

## Horizontal boat controller.
## Moves left/right via TouchInputManager. Locked when magnet is not IDLE.
## Speed formula (GDD): effective_speed = base_speed * (1 + permanent_speed_bonus) * roguelite_speed_multiplier

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

signal position_changed(new_x: float)

# ---------------------------------------------------------------------------
# Exports
# ---------------------------------------------------------------------------

@export_group("Movement")
@export_range(200.0, 600.0, 10.0) var base_speed: float = 400.0
@export_range(0.0, 1.0, 0.05) var permanent_speed_bonus: float = 0.0
@export_range(0.5, 2.0, 0.1) var roguelite_speed_multiplier: float = 1.0

@export_group("Boundaries")
@export var scene_left: float = 0.0
@export var scene_right: float = 720.0

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

var _can_move: bool = true
var _move_direction: float = 0.0
var _prev_x: float = 0.0

# ---------------------------------------------------------------------------
# Child references
# ---------------------------------------------------------------------------

@onready var _camera: Camera2D = $Camera2D
@onready var _magnet_mount: Marker2D = $MagnetMount

# ---------------------------------------------------------------------------
# Built-in
# ---------------------------------------------------------------------------

func _ready() -> void:
	_prev_x = position.x
	TouchInputManager.move_direction_changed.connect(_on_move_direction_changed)
	position.x = clampf(position.x, scene_left, scene_right)
	_try_load_sprite("res://assets/sprites/boat/boat.png")


func _physics_process(_delta: float) -> void:
	velocity.y = 0.0

	if _can_move and _move_direction != 0.0:
		var effective_speed: float = base_speed * (1.0 + permanent_speed_bonus) * roguelite_speed_multiplier
		velocity.x = _move_direction * effective_speed
	else:
		velocity.x = 0.0

	move_and_slide()
	position.x = clampf(position.x, scene_left, scene_right)

	if not is_equal_approx(position.x, _prev_x):
		_prev_x = position.x
		position_changed.emit(position.x)


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

func set_can_move(enabled: bool) -> void:
	_can_move = enabled
	if not enabled:
		velocity = Vector2.ZERO


func get_effective_speed() -> float:
	return base_speed * (1.0 + permanent_speed_bonus) * roguelite_speed_multiplier


func get_magnet_mount_global_position() -> Vector2:
	return _magnet_mount.global_position


func set_camera_active(active: bool) -> void:
	_camera.enabled = active


# ---------------------------------------------------------------------------
# Callbacks
# ---------------------------------------------------------------------------

func _on_move_direction_changed(direction: float) -> void:
	_move_direction = direction


## Try to load a real sprite texture; keep placeholder if file missing.
func _try_load_sprite(path: String) -> void:
	if ResourceLoader.exists(path):
		$Sprite2D.texture = load(path)
		$Sprite2D.modulate = Color.WHITE
