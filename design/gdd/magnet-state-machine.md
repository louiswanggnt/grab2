# 磁鐵狀態機 (Magnet State Machine)

> **Status**: In Design
> **Author**: user + agents
> **Last Updated**: 2026-03-25
> **Implements Pillar**: 一次下潛的滿足感（核心系統）

## Overview

磁鐵狀態機是 Grab2 的核心遊戲系統，驅動整個 30 秒級的 moment-to-moment 循環。它管理磁鐵從釋放→下沉→回收→兌換的完整生命週期，處理物理模擬、輸入響應、物件偵測和狀態轉換。這是遊戲「手感」的直接載體 — 如果這個系統不好玩，整個遊戲不會好玩。

## Player Fantasy

「放下磁鐵的瞬間就像擲骰子 — 你瞄準了目標，但水流和重力帶來的不確定性讓每次下潛都是一場小冒險。看到磁鐵吸住一個發光遺物的瞬間，心跳加速。」

## Detailed Design

### Core Rules

#### 狀態定義

磁鐵有 4 個狀態，嚴格順序循環：

```
IDLE → SINKING → RETRIEVING → CHECK → IDLE (loop)
```

#### 1. IDLE（待機/瞄準）

- 磁鐵固定在船的 MagnetMount 位置
- 跟隨船左右移動
- 等待玩家點擊（tap）觸發下潛
- **進入條件**: 回合開始 / CHECK 完成
- **離開條件**: 玩家 tap → SINKING

#### 2. SINKING（下沉）

- 磁鐵受重力影響向下移動：`velocity.y += gravity * delta`
- 玩家可透過滑動/滑鼠施加 X 軸微調力道（steering）
- Area2D 碰撞偵測開啟，碰到可吸附物件即吸附
- 下沉有最大深度限制 `max_depth`，到達後自動轉 RETRIEVING
- **進入條件**: IDLE 時玩家 tap
- **離開條件**:
  - 玩家長按 → RETRIEVING（需已下沉 `min_sink_distance`）
  - 到達 `max_depth` → RETRIEVING（自動）
  - 回合計時器 EXPIRED → RETRIEVING（強制）

#### 3. RETRIEVING（回收）

- 磁鐵持續向上移動，速度受吸附物總重量影響
- `retrieve_speed = base_retrieve_speed / (1 + total_weight * weight_drag_factor)`
- 玩家無法操控（自動上升）
- 上升過程中仍可吸附碰到的物件（Area2D 保持開啟）
- **進入條件**: SINKING 時長按 / 到達最大深度 / 計時器到期
- **離開條件**: 到達水面（position.y <= surface_y）→ CHECK

#### 4. CHECK（兌換）

- 磁鐵回到船上，自動進入兌換流程
- 回合計時器暫停
- 依序處理所有吸附物件：
  - **Metal**: value 轉換為金錢，加入本局收益
  - **Junk**: 顯示（低/零價值），無特殊效果
  - **Relic**: 觸發 Roguelite 三選一升級介面
  - **Chest**: 開箱動畫，隨機獎勵
- 所有物件處理完畢後清除吸附列表
- **進入條件**: RETRIEVING 時到達水面
- **離開條件**: 所有物件處理完畢 + 升級選擇完成 → IDLE

### States and Transitions

| From | To | Trigger | Guard Condition |
|------|----|---------|----------------|
| IDLE | SINKING | 玩家 tap | 回合計時未到期 |
| SINKING | RETRIEVING | 玩家長按 | `position.y > surface_y + min_sink_distance` |
| SINKING | RETRIEVING | 自動 | `position.y >= max_depth` |
| SINKING | RETRIEVING | 強制 | 回合計時 EXPIRED |
| RETRIEVING | CHECK | 自動 | `position.y <= surface_y` |
| CHECK | IDLE | 自動 | 所有物件處理完畢 |

#### 不合法轉換（明確禁止）

- IDLE → RETRIEVING（不能跳過下沉）
- IDLE → CHECK（不能跳過下沉和回收）
- SINKING → IDLE（不能在水下直接回到待機）
- SINKING → CHECK（不能跳過回收）
- RETRIEVING → SINKING（不能回頭）
- CHECK → SINKING（不能跳過待機）

### Physics Parameters

| Parameter | Default | Range | Description |
|-----------|---------|-------|-------------|
| `gravity` | 600 px/s² | 300-1000 | 下沉加速度 |
| `max_sink_speed` | 500 px/s | 300-800 | 下沉最大速度（terminal velocity） |
| `base_retrieve_speed` | 300 px/s | 200-500 | 無負重回收速度 |
| `steering_power` | 150 px/s | 50-300 | X 軸微調力道 |
| `steering_damping` | 0.85 | 0.5-0.95 | X 軸速度衰減（模擬水阻力） |
| `max_depth` | 2000 px | 1500-3000 | 最大下潛深度 |
| `min_sink_distance` | 100 px | 50-200 | 防誤觸回收的最小下沉距離 |
| `surface_y` | 船的 MagnetMount.y | — | 水面高度 |

### Interactions with Other Systems

| 系統 | 方向 | 數據流 |
|------|------|--------|
| **觸控輸入系統** | → 讀取 | tap（釋放磁鐵）、hold（回收）、swipe（X 軸微調） |
| **物資資料庫** | → 讀取 | 確認碰到的物件是否 magnetic |
| **物件吸附系統** | ← 輸出 | 通知「碰到物件」事件，吸附邏輯由該系統處理 |
| **經濟系統** | ← 輸出 | CHECK 狀態時傳遞吸附物件列表進行兌換 |
| **回合計時系統** | → 讀取 | 監聽 EXPIRED 信號強制回收；IDLE→SINKING 啟動計時 |
| **鏡頭系統** | ← 輸出 | 提供當前狀態和位置，Camera 據此切換目標 |
| **船控制器** | ← 輸出 | 提供當前狀態，船據此決定是否可移動 |
| **回合管理器** | ← 輸出 | 發出狀態變化信號 |

### Signals

```gdscript
signal state_changed(old_state: State, new_state: State)
signal item_contacted(item: Node2D)           # SINKING/RETRIEVING 碰到物件
signal surface_reached(attached_items: Array)  # 到達水面，進入 CHECK
signal check_completed()                       # CHECK 結束，回到 IDLE
```

## Formulas

### 下沉運動

```
velocity.y = min(velocity.y + gravity * delta, max_sink_speed)
position.y += velocity.y * delta
```

### X 軸微調

```
velocity.x += input_delta_x * steering_power * delta
velocity.x *= steering_damping
position.x += velocity.x * delta
```

### 回收速度（引用 item-database.md 公式）

```
total_weight = sum(item.weight for item in attached_items)
retrieve_speed = base_retrieve_speed / (1 + total_weight * weight_drag_factor)
position.y -= retrieve_speed * delta
```

## Edge Cases

| Edge Case | Resolution |
|-----------|-----------|
| 吸附數量達到 `max_attach_count` 時碰到新物件 | 忽略新物件，發出 `attachment_full` 信號給 HUD 顯示提示 |
| SINKING 碰到場景左右邊界 | clamp position.x 在場景範圍內 |
| 回收途中碰到其他物件 | 若未滿載則吸附（bonus catch），已滿則忽略 |
| 速度修改導致回收速度 < 50 px/s | clamp 最低速度為 50 px/s，避免卡住 |
| CHECK 期間 Relic 觸發升級但升級池為空 | 改為金錢獎勵（item.value × 3） |
| 同一幀碰到多個物件 | 全部吸附（直到滿載），按碰撞順序處理 |
| 玩家在 CHECK 完成前退出遊戲 | 自動完成 CHECK，結果存入回合結算 |

## Dependencies

### Upstream
- **觸控輸入系統** (hard) — 所有輸入事件
- **物資資料庫** (hard) — 物件是否可吸附的判定

### Downstream
- **物件吸附系統** (hard) — 碰撞事件觸發吸附邏輯
- **經濟系統** (hard) — CHECK 時的兌換流程
- **鏡頭系統** (hard) — 狀態決定 Camera 目標
- **船控制器** (hard) — 狀態決定船是否可移動
- **回合管理器** (hard) — 狀態變化驅動回合進度
- **HUD** (soft) — 顯示當前狀態相關 UI

## Tuning Knobs

| Knob | Default | Safe Range | Affects | Too High | Too Low |
|------|---------|-----------|---------|----------|---------|
| `gravity` | 600 | 300-1000 | 下沉速度 | 玩家來不及反應 | 下沉太慢無聊 |
| `max_sink_speed` | 500 | 300-800 | 最高下沉速度 | 操控感喪失 | 下潛耗時太久 |
| `steering_power` | 150 | 50-300 | X 軸操控力道 | 磁鐵像自由移動 | 微調無感 |
| `steering_damping` | 0.85 | 0.5-0.95 | 水阻力感 | 磁鐵太滑 | 操控太遲鈍 |
| `base_retrieve_speed` | 300 | 200-500 | 回收速度 | 回收太快無緊張感 | 回收太慢浪費時間 |
| `weight_drag_factor` | 0.15 | 0.05-0.3 | 重量對速度影響 | 重物無法回收 | 重量無意義 |
| `max_attach_count` | 5 | 3-8 | 最大吸附數 | 回合太短 | 策略空間太小 |
| `min_sink_distance` | 100 | 50-200 | 防誤觸門檻 | 淺水物件無法回收 | 容易誤觸 |

## Acceptance Criteria

1. **AC-01**: 狀態嚴格按 IDLE→SINKING→RETRIEVING→CHECK→IDLE 循環
2. **AC-02**: 不合法的狀態轉換不會發生
3. **AC-03**: SINKING 時重力加速度和 terminal velocity 正確
4. **AC-04**: SINKING 時 X 軸微調操控有水阻力手感
5. **AC-05**: RETRIEVING 速度隨吸附物總重量降低
6. **AC-06**: CHECK 正確依序處理 Metal/Junk/Relic/Chest
7. **AC-07**: `min_sink_distance` 防誤觸機制正常
8. **AC-08**: 到達 `max_depth` 自動回收
9. **AC-09**: 回合計時到期時強制回收
10. **AC-10**: 所有 signals 在正確時機發出

## Open Questions

1. SINKING 時是否加入輕微水流隨機擾動（drift）？— 原型測試手感
2. RETRIEVING 時是否允許 X 軸微調（讓回收路徑也有操控性）？— 原型測試
3. CHECK 的兌換動畫節奏：逐個顯示 vs 一次性結算？— 待 UX 設計
