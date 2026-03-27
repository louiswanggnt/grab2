extends RigidBody2D

## Metal object that can be picked up by the magnet.
## weight and value are set by the spawner via set_metal_properties().

var weight: float = 1.0
var value: int = 10


func _ready() -> void:
	add_to_group("metal")


## Sprite paths per weight tier. Fallback to placeholder + color if missing.
const TIER_SPRITES: Dictionary = {
	1.0: "res://assets/sprites/items/metal_light.png",
	2.0: "res://assets/sprites/items/metal_medium.png",
	3.0: "res://assets/sprites/items/metal_heavy.png",
	5.0: "res://assets/sprites/items/metal_rare.png",
}


func set_metal_properties(p_weight: float, p_value: int, p_size: float) -> void:
	weight = p_weight
	value = p_value
	mass = p_weight

	# Try loading tier-specific sprite
	var sprite_path: String = TIER_SPRITES.get(p_weight, "")
	if sprite_path != "" and ResourceLoader.exists(sprite_path):
		$Sprite2D.texture = load(sprite_path)
		$Sprite2D.modulate = Color.WHITE
		# Scale to target size based on actual texture
		var tex_size: float = maxf($Sprite2D.texture.get_width(), 1.0)
		var scale_factor: float = p_size / tex_size
		$Sprite2D.scale = Vector2(scale_factor, scale_factor)
	else:
		# Fallback: scale placeholder and tint by weight
		var scale_factor: float = p_size / 20.0
		$Sprite2D.scale = Vector2(scale_factor, scale_factor)
		var t: float = clampf(p_weight / 5.0, 0.0, 1.0)
		$Sprite2D.modulate = Color(
			lerpf(0.55, 0.85, t),
			lerpf(0.45, 0.65, t),
			lerpf(0.35, 0.15, t),
			1.0
		)

	# Update collision shape to match size
	var shape: RectangleShape2D = $CollisionShape2D.shape as RectangleShape2D
	if shape:
		shape = shape.duplicate()
		shape.size = Vector2(p_size, p_size)
		$CollisionShape2D.shape = shape
