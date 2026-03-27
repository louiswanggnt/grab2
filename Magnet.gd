extends Area2D

enum State { IDLE, DROPPING, RETRACTING }
var current_state = State.IDLE

var drop_speed = 400.0
var retract_speed = 500.0
var max_depth = 1800.0
var initial_pos_y = 0.0

var attached_items = []
@onready var catch_point = $CatchPoint
@onready var camera = $Camera2D
@onready var rope = $Rope

signal returned_to_surface(items)

func _ready():
	area_entered.connect(_on_area_entered)
	camera.enabled = false
	initial_pos_y = position.y
	# 初始隱藏繩子或設置點
	rope.clear_points()
	rope.add_point(Vector2.ZERO)
	rope.add_point(Vector2(0, -2000))

func _process(delta):
	# 更新繩子視覺效果（相對於磁鐵，繩子往上連到船）
	rope.set_point_position(1, Vector2(0, -position.y + initial_pos_y))
	
	match current_state:
		State.IDLE:
			camera.enabled = false
			position.y = initial_pos_y
		State.DROPPING:
			camera.enabled = true
			position.y += drop_speed * delta
			if position.y >= max_depth:
				current_state = State.RETRACTING
		State.RETRACTING:
			camera.enabled = true
			position.y -= retract_speed * delta
			if position.y <= initial_pos_y:
				position.y = initial_pos_y
				current_state = State.IDLE
				returned_to_surface.emit(attached_items)
				attached_items.clear()

func start_dropping():
	if current_state == State.IDLE:
		current_state = State.DROPPING

func start_retracting():
	# 只有在下降一段距離後才允許回收，避免點擊瞬間誤判
	if current_state == State.DROPPING and position.y > initial_pos_y + 20:
		current_state = State.RETRACTING

func _on_area_entered(area):
	if area.is_in_group("metal") and current_state != State.IDLE:
		if area not in attached_items:
			attached_items.append(area)
			# 使用 call_deferred 處理物理狀態改變
			call_deferred("_attach_metal", area)

func _attach_metal(area):
	if area.get_parent():
		area.get_parent().remove_child(area)
	catch_point.add_child(area)
	area.position = Vector2.ZERO
	area.monitoring = false
