extends CharacterBody2D

var speed = 400.0
var money = 0

@onready var magnet_mount = $MagnetMount
@onready var camera = $Camera2D
@onready var magnet_scene = preload("res://Magnet.tscn")
var magnet = null

func _ready():
	magnet = magnet_scene.instantiate()
	add_child(magnet)
	magnet.position = magnet_mount.position
	magnet.returned_to_surface.connect(_on_magnet_returned)

func _physics_process(delta):
	if magnet.current_state == magnet.State.IDLE:
		camera.enabled = true
		var direction = Input.get_axis("move_left", "move_right")
		velocity.x = direction * speed
	else:
		velocity.x = 0
		camera.enabled = false # 當磁鐵下放時，使用磁鐵的 Camera
	
	move_and_slide()

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# 點擊一下釋放磁鐵
			if event.pressed and magnet.current_state == magnet.State.IDLE:
				magnet.start_dropping()

func _process(delta):
	# 當磁鐵正在下潛且玩家按住滑鼠時，才進行回收
	if magnet.current_state == magnet.State.DROPPING:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			# 這裡的 start_retracting 內部已有位移判斷，避免點擊瞬間觸發
			magnet.start_retracting()

func _on_magnet_returned(items):
	var earnings = items.size() * 10
	money += earnings
	# 清除吸附物體
	for item in items:
		item.queue_free()
