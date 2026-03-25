# 船控制器 (Boat Controller)

> **Status**: In Design
> **Author**: user + agents
> **Last Updated**: 2026-03-25
> **Implements Pillar**: 一次下潛的滿足感 / NOT 複雜操作

## Overview

船控制器管理玩家的船體水平移動。船是磁鐵的載體 — 磁鐵的下潛起始位置由船的 X 座標決定。船只在磁鐵 IDLE 狀態時可移動，其他狀態下鎖定位置。這是一個輕量系統，但直接影響玩家的「瞄準」策略（選擇從哪個 X 位置下潛）。

## Player Fantasy

「駕駛打撈船在海面巡航，尋找最佳下潛點」。移動應該流暢輕快，不是遊戲的挑戰點 — 真正的技巧在水下。

## Detailed Design

### Core Rules

1. 船沿 X 軸水平移動，Y 軸固定在水面高度
2. 只在磁鐵 `IDLE` 狀態時接受移動輸入
3. 移動使用 `CharacterBody2D.move_and_slide()`
4. 船不能超出場景邊界（左右牆壁碰撞）
5. 移動速度為 `base_speed`，可被永久升級和 Roguelite 升級修改

#### 速度修改

```gdscript
effective_speed = base_speed * (1 + permanent_speed_bonus) * roguelite_speed_multiplier
```

| Variable | Default | Range |
|----------|---------|-------|
| `base_speed` | 400 px/s | 200-600 |
| `permanent_speed_bonus` | 0.0 | 0.0-1.0 (永久升級累加) |
| `roguelite_speed_multiplier` | 1.0 | 0.5-2.0 (本局遺物加成) |

### States and Transitions

船本身無獨立狀態機 — 它的可操作性由磁鐵狀態機的當前狀態決定：

| 磁鐵狀態 | 船行為 |
|---------|--------|
| IDLE | 可自由左右移動 |
| SINKING | 鎖定位置（velocity = 0） |
| RETRIEVING | 鎖定位置 |
| CHECK | 鎖定位置 |

### Interactions with Other Systems

| 系統 | 方向 | 數據流 |
|------|------|--------|
| **觸控輸入系統** | → 讀取 | 接收水平移動方向 (-1, 0, 1) |
| **磁鐵狀態機** | → 讀取 | 讀取當前狀態，決定是否接受移動 |
| **永久進度系統** | → 讀取 | 讀取 `permanent_speed_bonus` |
| **Roguelite 升級系統** | → 讀取 | 讀取 `roguelite_speed_multiplier` |
| **鏡頭系統** | ← 輸出 | 提供船位置給 Camera2D 追蹤 |

## Formulas

見 Core Rules 的速度修改公式。

## Edge Cases

| Edge Case | Resolution |
|-----------|-----------|
| 船碰到場景左/右邊界 | `move_and_slide()` + StaticBody2D 牆壁自然處理 |
| 磁鐵從 IDLE 切到 SINKING 的瞬間船正在移動 | 立即將 velocity 歸零，船停在當前位置 |
| 速度加成後超過畫面寬度/秒 | clamp `effective_speed` 上限為 800 px/s |

## Dependencies

### Upstream
- **觸控輸入系統** (hard) — 移動方向輸入

### Downstream
- **鏡頭系統** (soft) — IDLE 時 Camera 跟隨船
- **磁鐵狀態機** (soft) — 磁鐵的初始 X 座標由船決定

## Tuning Knobs

| Knob | Default | Safe Range | Affects |
|------|---------|-----------|---------|
| `base_speed` | 400 | 200-600 | 船移動速度。太快→瞄準困難，太慢→移動無聊 |
| `acceleration` | 即時 | 0-0.3s | 是否有加速度。0=即時響應，>0=慣性感 |

## Acceptance Criteria

1. **AC-01**: A/D 鍵（PC）或觸控（手機）可左右移動船
2. **AC-02**: 磁鐵非 IDLE 狀態時船無法移動
3. **AC-03**: 船不會超出場景邊界
4. **AC-04**: 速度加成（永久+Roguelite）正確生效
5. **AC-05**: 移動手感流暢，無卡頓

## Open Questions

1. 是否需要船的視覺傾斜動畫（移動時微傾）？— 待美術決定
