# 經濟系統 (Economy System)

> **Status**: In Design
> **Author**: user + agents
> **Last Updated**: 2026-03-25
> **Implements Pillar**: 4 分鐘就是一個完整體驗 / 每局都不一樣

## Overview

經濟系統管理遊戲中唯一的貨幣「金錢」的流入（物資兌換）和流出（永久升級購買）。它是連接局內操作層和跨局成長層的橋樑 — 玩家在局內賺錢，在局外花錢。此系統需要確保：早期有成長感、中期有策略選擇、後期不會「升滿無動力」。

## Player Fantasy

「每一次成功的下潛都讓我離下一次升級更近。看到金幣數字增長的感覺，就像存錢罐越來越滿 — 直到我終於買得起那個新升級。」

## Detailed Design

### Core Rules

#### 貨幣定義

遊戲只有一種貨幣：**金錢 (Money)**
- 來源：物資兌換（唯一流入）
- 用途：永久升級購買（唯一流出）
- 持久化：跨局保存（存檔系統）

#### 兌換流程（CHECK 狀態內）

磁鐵回到水面時，依序處理吸附物件：

```
for item in attached_items:
    match item.category:
        METAL:
            earnings += item.value
        JUNK:
            earnings += item.value  # 通常 0-2
        RELIC:
            trigger_roguelite_upgrade(item)
            # Relic 本身不給金錢
        CHEST:
            chest_reward = roll_chest_reward(item)
            earnings += chest_reward
```

#### 回合結算

回合結束時計算本局總收益：

```
round_earnings = sum(all_check_earnings)
total_money += round_earnings
```

> 沒有「回合結束獎勵」或「連續遊玩加成」— 收入純粹來自撈到的東西。保持簡單透明。

#### 永久升級定價

使用遞增定價模型，每次升級同一項目費用增加：

```
upgrade_cost = base_cost * (1 + level * cost_scaling)
```

| Variable | Definition | Default |
|----------|-----------|---------|
| `base_cost` | 升級基礎價格 | 因升級項而異 |
| `level` | 當前升級等級 (0-based) | 0 |
| `cost_scaling` | 每級費用增長率 | 0.5 |

#### 永久升級項目（MVP）

| 升級 | base_cost | max_level | 效果 per level | 說明 |
|------|-----------|-----------|---------------|------|
| 磁力強度 | 50 | 10 | +1 max_attach_count | 能吸更多物件 |
| 回收速度 | 80 | 8 | +10% base_retrieve_speed | 回收更快 |
| 船速 | 40 | 5 | +10% base_speed | 瞄準更快 |
| 磁鐵操控 | 60 | 5 | +15% steering_power | X 軸微調更靈活 |

### States and Transitions

經濟系統為純數據/邏輯系統，無運行時狀態機。

### Interactions with Other Systems

| 系統 | 方向 | 數據流 |
|------|------|--------|
| **物資資料庫** | → 讀取 | 物件的 value 和 category |
| **磁鐵狀態機** | → 讀取 | CHECK 狀態時接收 attached_items 列表 |
| **永久進度系統** | ← 輸出 | 提供「購買升級」介面：扣除金錢，套用效果 |
| **存檔系統** | ←→ 雙向 | 讀取/寫入 total_money 和升級等級 |
| **HUD** | ← 輸出 | 提供 money、round_earnings 給 HUD 顯示 |
| **商店 UI** | ← 輸出 | 提供升級列表、當前等級、費用、可購買狀態 |
| **Roguelite 升級系統** | ← 輸出 | CHECK 時若 Relic 出現但升級池空，替代給予 value × 3 金錢 |

## Formulas

### 升級費用

```
cost(level) = base_cost * (1 + level * cost_scaling)
```

**範例：磁力強度** (base_cost=50, cost_scaling=0.5)

| Level | Cost | Cumulative |
|-------|------|-----------|
| 0→1 | 50 | 50 |
| 1→2 | 75 | 125 |
| 2→3 | 100 | 225 |
| 3→4 | 125 | 350 |
| 4→5 | 150 | 500 |
| 9→10 | 275 | 1,625 |

### 預期收入估算（用於平衡驗證）

假設每局 4-6 次下潛，每次平均吸附 3-4 個物件：

| 階段 | 平均每局收入 | 說明 |
|------|------------|------|
| 早期（無升級） | 60-100 | 多 COMMON Metal，少 Junk |
| 中期（幾項升級） | 120-200 | 更多吸附 + 更深 = 更高價值 |
| 後期（接近滿級） | 200-350 | RARE/EPIC Metal + Chest |

> 設計意圖：早期 1-2 局買一個升級，中期 2-3 局，後期 4-5 局。漸進放緩但不停滯。

### Chest 獎勵公式

```
chest_reward = randi_range(chest_min_reward, chest_max_reward)
```

| Variable | Default | Range |
|----------|---------|-------|
| `chest_min_reward` | 30 | 20-50 |
| `chest_max_reward` | 120 | 80-200 |

## Edge Cases

| Edge Case | Resolution |
|-----------|-----------|
| 金錢不足以購買任何升級 | 商店 UI 灰化不可購買項目，繼續遊玩賺錢 |
| 所有升級已滿級 | 金錢仍然累積，為未來內容（新海域、新升級）準備 |
| 回合收益為 0（只撈到 Junk） | 正常結算，顯示「$0」— 這是策略失敗的回饋 |
| 整數溢出 | 金錢使用 int，上限 2^31。實際不可能達到 |
| CHECK 中途遊戲崩潰 | 存檔在 CHECK 完成後寫入。崩潰 = 本次 CHECK 收益丟失（可接受） |

## Dependencies

### Upstream
- **物資資料庫** (hard) — 物件 value 定義

### Downstream
- **永久進度系統** (hard) — 升級購買需要扣除金錢
- **HUD** (soft) — 顯示金錢
- **商店 UI** (soft) — 升級介面

## Tuning Knobs

| Knob | Default | Safe Range | Affects | Too High | Too Low |
|------|---------|-----------|---------|----------|---------|
| `cost_scaling` | 0.5 | 0.2-1.0 | 升級費用增長速度 | 後期完全買不起 | 升級太快無挑戰 |
| `chest_min_reward` | 30 | 20-50 | Chest 最低獎勵 | Chest 永遠好 | Chest 可能讓人失望 |
| `chest_max_reward` | 120 | 80-200 | Chest 最高獎勵 | 金錢膨脹太快 | Chest 風險不值得 |
| 各升級 `max_level` | 5-10 | 3-15 | 成長上限 | 遊戲太長 | 太快畢業 |

## Acceptance Criteria

1. **AC-01**: CHECK 時 Metal 的 value 正確轉為金錢
2. **AC-02**: Junk 兌換為 0-2 金錢（不是負數）
3. **AC-03**: Chest 獎勵在 min-max 範圍內隨機
4. **AC-04**: 升級費用按公式正確遞增
5. **AC-05**: 金錢不足時無法購買升級
6. **AC-06**: 升級達到 max_level 後不可再購買
7. **AC-07**: 金錢跨局保存（存檔系統整合）
8. **AC-08**: 回合結算顯示正確的本局總收益

## Open Questions

1. 是否需要「賣出升級」功能（refund）？— 初步設計為不需要，避免複雜度
2. 後期是否引入第二貨幣（如「深海寶石」）用於解鎖高階內容？— 待 Vertical Slice 評估
3. Chest 獎勵是否應根據深度帶調整 min/max？— 待物資生成系統設計
