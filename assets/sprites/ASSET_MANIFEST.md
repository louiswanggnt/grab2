# Sprite Asset Manifest

> All game sprites are managed here. Place files at the listed paths and they will be loaded automatically by the corresponding scene files.

## Game Objects

| Asset | Path | Size (px) | Scene | Status |
|-------|------|-----------|-------|--------|
| Boat | `assets/sprites/boat/boat.png` | 100x40 | `Boat.tscn` | Pending |
| Magnet | `assets/sprites/magnet/magnet.png` | 40x30 | `Magnet.tscn` | Pending |
| Fish | `assets/sprites/items/fish.png` | 30x20 | `Fish.tscn` | Pending |

## Metal Objects (by tier — supports variants)

每個 tier 支援多個視覺變體。命名規則：`metal_{tier}{nn}.png`（例如 `metal_medium01.png`）。
若該 tier 只有一張圖，也可使用 `metal_{tier}.png` 作為 fallback。

同一 tier 的所有 variant 共用相同的 **weight** 和 **size**，但有不同的 **value**（金額）。

### Light (weight: 1.0, size: 20px)

| Variant | Path | Value | Status |
|---------|------|-------|--------|
| 01 | `assets/sprites/items/metal_light01.png` | $3 | Pending |
| 02 | `assets/sprites/items/metal_light02.png` | $5 | Pending |
| 03 | `assets/sprites/items/metal_light03.png` | $7 | Pending |
| (fallback) | `assets/sprites/items/metal_light.png` | — | ✅ Uploaded |

### Medium (weight: 2.0, size: 28px)

| Variant | Path | Value | Status |
|---------|------|-------|--------|
| 01 | `assets/sprites/items/metal_medium01.png` | $10 | Pending |
| 02 | `assets/sprites/items/metal_medium02.png` | $15 | Pending |
| 03 | `assets/sprites/items/metal_medium03.png` | $20 | Pending |
| (fallback) | `assets/sprites/items/metal_medium.png` | — | Pending |

### Heavy (weight: 3.0, size: 36px)

| Variant | Path | Value | Status |
|---------|------|-------|--------|
| 01 | `assets/sprites/items/metal_heavy01.png` | $25 | Pending |
| 02 | `assets/sprites/items/metal_heavy02.png` | $30 | Pending |
| 03 | `assets/sprites/items/metal_heavy03.png` | $40 | Pending |
| (fallback) | `assets/sprites/items/metal_heavy.png` | — | ✅ Uploaded |

### Rare (weight: 5.0, size: 48px)

| Variant | Path | Value | Status |
|---------|------|-------|--------|
| 01 | `assets/sprites/items/metal_rare01.png` | $50 | Pending |
| 02 | `assets/sprites/items/metal_rare02.png` | $60 | Pending |
| 03 | `assets/sprites/items/metal_rare03.png` | $80 | Pending |
| (fallback) | `assets/sprites/items/metal_rare.png` | — | Pending |

## Environment

| Asset | Path | Size (px) | Scene | Status |
|-------|------|-----------|-------|--------|
| Sea Background | (procedural gradient) | 720x2000 | `Main.tscn` | Code-generated |
| Surface | (procedural) | 720x100 | `Main.tscn` | Code-generated |

## UI

| Asset | Path | Size (px) | Used in | Status |
|-------|------|-----------|---------|--------|
| Shop Icon | `assets/sprites/ui/shop_icon.png` | 64x64 | `Main.gd` (shop button) | Pending (uses emoji fallback) |

## Guidelines

- **Format**: PNG with transparency
- **Style**: Pixel art, consistent palette
- **Viewport**: 720x1280 portrait
- **Naming**: snake_case, descriptive; variants use 2-digit suffix (01, 02, 03)
- **Collision**: Collision shapes are independent of sprite size; no need to match exactly
- **Sizes**: All display sizes are controlled via `GameConfig` — sprites are auto-scaled to fit
