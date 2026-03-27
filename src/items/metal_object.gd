extends RigidBody2D

## Metal object that can be picked up by the magnet.
## Properties are set by the spawner via set_metal_properties().

var weight: float = 1.0
var value: int = 10
var tier_id: String = ""
var variant_index: int = 0


func _ready() -> void:
	add_to_group("metal")


## Configure this metal object.
## p_weight     — physics weight (affects retrieval drag)
## p_value      — money earned on collection
## p_size       — collision & display size in pixels
## p_tier_id    — tier identifier (e.g. "light", "medium") for sprite lookup
## p_variant_idx — which variant (0-based) for numbered sprites
func set_metal_properties(p_weight: float, p_value: int, p_size: float,
		p_tier_id: String = "", p_variant_idx: int = 0) -> void:
	weight = p_weight
	value = p_value
	mass = p_weight
	tier_id = p_tier_id
	variant_index = p_variant_idx

	# Try loading variant sprite: metal_{id}{nn}.png → fallback metal_{id}.png
	var loaded: bool = false
	if tier_id != "":
		# First try numbered variant: metal_light01.png
		var variant_path: String = "res://assets/sprites/items/metal_%s%02d.png" % [
			tier_id, p_variant_idx + 1]
		if ResourceLoader.exists(variant_path):
			_apply_sprite(load(variant_path), p_size)
			loaded = true
		else:
			# Fallback to single sprite: metal_light.png
			var fallback_path: String = "res://assets/sprites/items/metal_%s.png" % tier_id
			if ResourceLoader.exists(fallback_path):
				_apply_sprite(load(fallback_path), p_size)
				loaded = true

	if not loaded:
		# Fallback: keep ColorRect placeholder, tint by weight
		var half: float = p_size / 2.0
		$ColorRect.offset_left = -half
		$ColorRect.offset_top = -half
		$ColorRect.offset_right = half
		$ColorRect.offset_bottom = half
		var t: float = clampf(p_weight / 5.0, 0.0, 1.0)
		$ColorRect.color = Color(
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


## Apply a loaded texture to the Sprite2D and hide the ColorRect fallback.
func _apply_sprite(tex: Texture2D, target_size: float) -> void:
	$Sprite2D.texture = tex
	$Sprite2D.visible = true
	$ColorRect.visible = false
	var tex_size: float = maxf(tex.get_width(), 1.0)
	var scale_factor: float = target_size / tex_size
	$Sprite2D.scale = Vector2(scale_factor, scale_factor)
