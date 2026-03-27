extends Node

## GameConfig — 遊戲所有可調數值的唯一來源。
## 所有腳本應從此處讀取數值，而非自行硬編碼。
## 修改此檔案即可調整整個遊戲的平衡。

# ==========================================================================
# 場景 / 世界
# ==========================================================================

## 場景寬度（X 軸範圍）
const SCENE_LEFT: float = 0.0
const SCENE_RIGHT: float = 1150.0

## 水面 Y 座標（以下為海中）
const SURFACE_Y: float = 100.0

## 海床 Y 座標
const SEABED_Y: float = 1000.0

## 磁鐵最大下沉深度（從水面算起）
const MAX_DEPTH: float = 1000.0

## 金屬物生成 X 軸範圍
const METAL_SPAWN_X_MIN: float = 50.0
const METAL_SPAWN_X_MAX: float = 1100.0

## 金屬物生成 Y 軸範圍（海床頂部附近）
const METAL_SEABED_TOP_Y: float = 1000.0
# ==========================================================================
# 船 (Boat)
# ==========================================================================

## 基礎移動速度
const BOAT_BASE_SPEED: float = 400.0

## SINKING 狀態下船的速度倍率
const BOAT_SINKING_SPEED_MULTIPLIER: float = 0.5

# ==========================================================================
# 磁鐵 (Magnet)
# ==========================================================================

## 下沉重力加速度
const MAGNET_SINK_GRAVITY: float = 600.0

## 最大下沉速度（terminal velocity）
const MAGNET_MAX_SINK_SPEED: float = 500.0

## 基礎回收上拉速度
const MAGNET_BASE_RETRIEVE_SPEED: float = 1600.0

## 左右操控力道
const MAGNET_STEERING_POWER: float = 150.0

## 左右操控阻尼（每幀 X 速度乘以此值，越小減速越快）
const MAGNET_STEERING_DAMPING: float = 0.85

## 重量對回收速度的影響係數
## 實際速度 = base_retrieve_speed / (1 + total_weight * WEIGHT_DRAG_FACTOR)
const MAGNET_WEIGHT_DRAG_FACTOR: float = 0.15

## 最大吸附物件數量
const MAGNET_MAX_ATTACH_COUNT: int = 3

## 吸附物品間的堆疊間距（像素）
const MAGNET_ATTACH_SPACING: float = 25.0

# ==========================================================================
# 金屬物 (Metal Objects)
# ==========================================================================

## 金屬物定義: [重量, 價值, 大小(像素), 數量]
## 重量影響: 回收速度減損、視覺大小
## 價值: 結算時獲得的金錢
const METAL_TIERS: Array = [
	[1.0, 5, 20.0, 50],     # Light — 小、低價值
	[2.0, 15, 28.0, 40],    # Medium
	[3.0, 30, 36.0, 25],    # Heavy
	[5.0, 60, 48.0, 10],    # Very Heavy — 大、高價值
]



# ==========================================================================
# 魚群 (Decorative Fish)
# ==========================================================================

## 魚的數量
const FISH_COUNT: int = 100

## 魚的 X 軸生成範圍
const FISH_SPAWN_X_MIN: float = -50.0
const FISH_SPAWN_X_MAX: float = 100.0

## 魚的 Y 軸生成範圍（海中區域）
const FISH_SPAWN_Y_MIN: float = 300.0
const FISH_SPAWN_Y_MAX: float = 800.0

## 魚的大小隨機範圍（縮放倍率）
const FISH_SCALE_MIN: float = 0.7
const FISH_SCALE_MAX: float = 1.5

## 魚的速度隨機範圍倍率（基礎速度的百分比）
const FISH_SPEED_VARIATION_MIN: float = 0.6
const FISH_SPEED_VARIATION_MAX: float = 1.4

## 魚的基礎游泳速度
const FISH_BASE_SWIM_SPEED: float = 60.0

## 魚的垂直漂浮幅度
const FISH_VERTICAL_DRIFT: float = 0.0

## 魚的折返邊界
const FISH_WRAP_LEFT: float = -50.0
const FISH_WRAP_RIGHT: float = 1200.0

# ==========================================================================
# 回合計時器 (Round Timer)
# ==========================================================================

## 每回合時間（秒）= 4 分鐘
const ROUND_DURATION: float = 240.0

## 進入緊急模式的剩餘秒數
const ROUND_URGENT_THRESHOLD: float = 30.0

# ==========================================================================
# 經濟 (Economy)
# ==========================================================================

## 升級費用倍率
const ECONOMY_COST_SCALING: float = 0.5

## 起始金錢
const ECONOMY_STARTING_MONEY: int = 0

## 寶箱隨機價值範圍
const CHEST_VALUE_MIN: int = 30
const CHEST_VALUE_MAX: int = 120

# ==========================================================================
# 輸入 (Touch Input)
# ==========================================================================

## Tap 最大持續時間（秒）
const TAP_MAX_DURATION: float = 0.2

## Hold 最小持續時間（秒）
const HOLD_MIN_DURATION: float = 0.3

## Swipe 最小距離（像素）
const SWIPE_MIN_DISTANCE: float = 30.0

## 操控靈敏度
const STEERING_SENSITIVITY: float = 0.3

## Tap 最大移動距離（像素，超過則取消 tap）
const TAP_MAX_DISTANCE: float = 30.0
