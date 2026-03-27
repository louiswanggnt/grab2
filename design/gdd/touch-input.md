# 觸控輸入系統 (Touch Input)

> **Status**: In Design
> **Author**: user + agents
> **Last Updated**: 2026-03-25
> **Implements Pillar**: 一次下潛的滿足感 / NOT 複雜操作

## Overview

觸控輸入系統是遊戲的輸入抽象層，將手機觸控手勢和 PC 滑鼠/鍵盤操作統一映射為遊戲動作。遊戲只需要三種輸入：水平移動（船）、點擊（釋放磁鐵）、長按+滑動（控制磁鐵）。此系統確保在手機和 PC 上都能有一致的操作體驗，同時遵守 Anti-Pillar「NOT 複雜操作」— 不加入多指手勢或虛擬搖桿。

## Player Fantasy

操控應該是「透明」的 — 玩家不應該意識到自己在「操作一個介面」，而是直覺地感覺自己在移動船、控制磁鐵。輸入延遲和手感問題會直接破壞 Pillar 1「一次下潛的滿足感」。

## Detailed Design

### Core Rules

#### 輸入動作映射

| 遊戲動作 | 手機觸控 | PC 滑鼠/鍵盤 | 觸發條件 |
|---------|---------|-------------|---------|
| **移動船 (左/右)** | 螢幕左半/右半長按 | A/D 鍵 | 磁鐵狀態 = IDLE |
| **釋放磁鐵** | 點擊（tap） | 滑鼠左鍵單擊 | 磁鐵狀態 = IDLE |
| **磁鐵 X 軸微調** | 左右滑動 | 滑鼠左右移動 | 磁鐵狀態 = SINKING |
| **開始回收** | 長按螢幕 | 長按滑鼠左鍵 | 磁鐵狀態 = SINKING，且已下沉一段距離 |

#### 手勢辨識參數

| 參數 | 定義 | 預設值 |
|------|------|--------|
| `tap_max_duration` | 點擊（tap）最長持續時間 | 200ms |
| `tap_max_distance` | 點擊（tap）最大位移容差 | 20px |
| `hold_min_duration` | 長按最短持續時間 | 300ms |
| `swipe_min_distance` | 滑動最小位移 | 30px |
| `steering_sensitivity` | SINKING 時 X 軸操控靈敏度 | 0.3 |

#### 輸入優先級

當多個輸入同時發生時的優先順序：
1. 回收（長按）— 最高，因為涉及「搶救」已吸附物
2. 釋放磁鐵（tap）
3. 移動船 — 最低，只在 IDLE 時有效

### States and Transitions

輸入系統本身無狀態 — 它讀取磁鐵狀態機的當前狀態來決定如何解讀輸入。

| 磁鐵狀態 | 有效輸入 | 無效輸入（忽略） |
|---------|---------|----------------|
| IDLE | 移動船、釋放磁鐵 | 滑動（無效果） |
| SINKING | X 軸微調、開始回收 | 移動船（鎖定） |
| RETRIEVING | 無（自動回收中） | 所有輸入忽略 |
| CHECK | UI 交互（選升級） | 遊戲輸入忽略 |

### Interactions with Other Systems

| 系統 | 方向 | 數據流 |
|------|------|--------|
| **船控制器** | ← 輸出 | 提供水平移動方向 (-1, 0, 1) |
| **磁鐵狀態機** | ← 輸出 / → 讀取 | 輸出：tap/hold 事件。讀取：當前狀態以決定輸入解讀 |
| **Roguelite 升級 UI** | ← 輸出 | CHECK 狀態時的 UI 點擊事件 |

## Formulas

### 磁鐵 X 軸操控力道

```
steering_force = input_delta_x * steering_sensitivity * steering_power
```

| Variable | Definition | Default | Range |
|----------|-----------|---------|-------|
| `input_delta_x` | 觸控/滑鼠的水平位移量 (px) | — | -screen_width ~ screen_width |
| `steering_sensitivity` | 靈敏度倍率 | 0.3 | 0.1-0.8 |
| `steering_power` | 力道基礎值 (px/s) | 150 | 50-300 |

> 注意：力道較小以維持「微調」的手感，不應讓磁鐵水平快速移動。

## Edge Cases

| Edge Case | Resolution |
|-----------|-----------|
| 玩家在 tap 過程中手指滑動超過容差 | 視為取消 tap，不釋放磁鐵 |
| 磁鐵剛釋放就立即長按（防止誤觸回收） | 需下沉至少 `min_sink_distance`（100px）後才接受回收輸入 |
| 多指觸控 | 只處理第一個觸控點，忽略其餘 |
| 螢幕旋轉 | 鎖定為直向（Portrait），不支援橫向 |
| 輸入延遲超過 100ms | 記錄 log，不做補償（物理模擬會自然處理） |

## Dependencies

### Upstream
- **無** — Foundation 層

### Downstream
- **船控制器** (hard) — 需要水平移動輸入
- **磁鐵狀態機** (hard) — 需要 tap/hold/swipe 事件

## Tuning Knobs

| Knob | Default | Safe Range | Affects | Too High | Too Low |
|------|---------|-----------|---------|----------|---------|
| `tap_max_duration` | 200ms | 100-400ms | tap 判定寬鬆度 | 長按被誤判為 tap | tap 很難觸發 |
| `hold_min_duration` | 300ms | 200-500ms | 長按判定 | 很難觸發回收 | tap 被誤判為長按 |
| `steering_sensitivity` | 0.3 | 0.1-0.8 | X 軸微調靈敏度 | 磁鐵難以控制 | 微調無感 |
| `min_sink_distance` | 100px | 50-200px | 防止誤觸回收的下沉門檻 | 淺水物件無法回收 | 可能誤觸 |

## Acceptance Criteria

1. **AC-01**: PC 上 A/D 可移動船，滑鼠點擊可釋放磁鐵，長按可回收
2. **AC-02**: 手機上觸控 tap 可釋放磁鐵，長按可回收
3. **AC-03**: SINKING 時滑動/滑鼠可微調磁鐵 X 軸位置
4. **AC-04**: IDLE 以外的狀態下，船移動被正確鎖定
5. **AC-05**: 磁鐵釋放後需下沉 100px 才能觸發回收（防誤觸）
6. **AC-06**: 多指觸控不會導致異常行為
7. **AC-07**: 輸入到畫面回饋延遲 < 50ms（體感即時）

## Open Questions

1. 手機端移動船是用螢幕左右半區長按，還是用虛擬按鈕？— 需原型測試手感
2. 是否需要「操控靈敏度」設定選項讓玩家自訂？— 待 Alpha 階段評估
