class_name ItemData
extends Resource

## Physical item definition for the item database.
## All spawnable items in the game are defined as ItemData resources (.tres).
## This is a pure data container — no runtime state or logic.

enum Category { METAL, RELIC, JUNK, CHEST }
enum Rarity { COMMON, UNCOMMON, RARE, EPIC }

## Unique identifier, e.g. "metal_iron_nail"
@export var id: String = ""
## Localized display name shown in HUD
@export var display_name: String = ""
## Item category determines gameplay behaviour on retrieval
@export var category: Category = Category.METAL
## Base monetary value (Junk = 0-2, Metal = 5-150+)
@export_range(0, 500, 1) var value: int = 0
## Weight (0.5-5.0) — reduces magnet retrieve speed
@export_range(0.1, 5.0, 0.1) var weight: float = 1.0
## Rarity tier affects spawn rate and visual glow
@export var rarity: Rarity = Rarity.COMMON
## Collision / visual footprint in pixels
@export var size: Vector2 = Vector2(32.0, 32.0)
## Pixel sprite — can be null for placeholder items during development
@export var sprite: Texture2D
## Shallowest depth (px from water surface) where this item can spawn
@export_range(0.0, 3000.0, 10.0) var depth_min: float = 800.0
## Deepest depth (px from water surface) where this item can spawn
@export_range(0.0, 3000.0, 10.0) var depth_max: float = 2000.0


## Returns true when the item can spawn at the given world depth.
func is_valid_at_depth(depth: float) -> bool:
	return depth >= depth_min and depth <= depth_max


## Returns the rarity as a display colour for HUD tinting.
## COMMON = white, UNCOMMON = green, RARE = blue, EPIC = purple.
func get_rarity_color() -> Color:
	match rarity:
		Rarity.UNCOMMON:
			return Color(0.4, 1.0, 0.4)   # green
		Rarity.RARE:
			return Color(0.4, 0.6, 1.0)   # blue
		Rarity.EPIC:
			return Color(0.8, 0.3, 1.0)   # purple
		_:
			return Color.WHITE
