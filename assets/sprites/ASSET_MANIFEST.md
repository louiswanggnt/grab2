# Sprite Asset Manifest

> All game sprites are managed here. Place files at the listed paths and they will be loaded automatically by the corresponding scene files.

## Game Objects

| Asset | Path | Size (px) | Scene | Status |
|-------|------|-----------|-------|--------|
| Boat | `assets/sprites/boat/boat.png` | 100x40 | `Boat.tscn` | Pending |
| Magnet | `assets/sprites/magnet/magnet.png` | 40x30 | `Magnet.tscn` | Pending |
| Fish | `assets/sprites/items/fish.png` | 30x20 | `Fish.tscn` | Pending |

## Metal Objects (by tier)

| Asset | Path | Size (px) | Weight | Value | Status |
|-------|------|-----------|--------|-------|--------|
| Metal Light | `assets/sprites/items/metal_light.png` | 20x20 | 1.0 | $5 | Pending |
| Metal Medium | `assets/sprites/items/metal_medium.png` | 28x28 | 2.0 | $15 | Pending |
| Metal Heavy | `assets/sprites/items/metal_heavy.png` | 36x36 | 3.0 | $30 | Pending |
| Metal Rare | `assets/sprites/items/metal_rare.png` | 48x48 | 5.0 | $60 | Pending |

## Environment

| Asset | Path | Size (px) | Scene | Status |
|-------|------|-----------|-------|--------|
| Sea Background | (procedural gradient) | 720x2000 | `Main.tscn` | Code-generated |
| Surface | (procedural) | 720x100 | `Main.tscn` | Code-generated |

## Guidelines

- **Format**: PNG with transparency
- **Style**: Pixel art, consistent palette
- **Viewport**: 720x1280 portrait
- **Naming**: snake_case, descriptive
- **Collision**: Collision shapes are independent of sprite size; no need to match exactly
