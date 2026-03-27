extends Area2D

var speed = 100.0
var direction = 1.0

func _ready():
	# 隨機速度與方向
	speed = randf_range(50, 200)
	direction = 1.0 if randf() > 0.5 else -1.0
	# Try real sprite, fallback to random color placeholder
	var sprite_path: String = "res://assets/sprites/items/fish.png"
	if ResourceLoader.exists(sprite_path):
		$Sprite2D.texture = load(sprite_path)
		$Sprite2D.modulate = Color.WHITE
	else:
		$Sprite2D.modulate = Color(randf(), randf(), 0, 1)

func _process(delta):
	position.x += direction * speed * delta
	
	# 碰到邊界折返
	if position.x < 50 or position.x > 1100:
		direction *= -1.0
		scale.x = -scale.x # 簡單的反向視覺效果
