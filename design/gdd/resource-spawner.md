# 物資生成系統 (Resource Spawner)

> **Status**: In Design
> **Author**: user + agents
> **Last Updated**: 2026-03-25
> **Implements Pillar**: 每局都不一樣 / 一次下潛的滿足感

## Overview

物資生成系統負責在每局開始時將物件隨機生成於海底地圖的指定深度帶。它從物資資料庫讀取物件定義，依據深度帶規則、稀有度機率、以及各類別數量上限，在地圖中放置實體物件節點。此系統是「每局都不一樣」支柱的直接技術載體 — 每局的物件分佈、種類組合和精確位置都不同，確保 Roguelite 的隨機性核心體驗。

## Player Fantasy

「沉入水底那一刻，我永遠不知道今天的海床長什麼樣子。也許這次深水區有一個寶箱，也許右邊有一個發光的遺物在等我。每局下潛前的那種期待感，就像每次開啟新地圖一樣。」

目標 MDA 美學：**Discovery（探索與發現）**— 不同的物件布局創造不同的探索路線。**Fantasy（幻想）**— 「這一局可能特別豐收」的心理預期。

## Detailed Design

### Core Rules

#### 1. 生成時機

- 生成在 **回合開始（Round Manager 發出 `round_started` 信號）後、玩家首次下潛前** 完成
- 生成為一次性批次操作，不在回合中途追加物件
- 生成完成後發出 `spawn_completed` 信號，回合管理器收到後才允許玩家釋放磁鐵

#### 2. 深度帶定義

地圖垂直分為三個深度帶，每帶有獨立的生成規則：

| 深度帶 | Y 座標範圍 (px) | 主要稀有度 | 說明 |
|--------|----------------|-----------|------|
| 淺水區 (Shallow) | 800-1200 | COMMON | 風險低、數量多、價值低 |
| 中水區 (Mid) | 1200-1600 | UNCOMMON | 均衡區域 |
| 深水區 (Deep) | 1600-2000 | RARE / EPIC | 風險高、數量少、價值高 |

> Y = 0 為船的 MagnetMount 位置（水面）。數值越大越深。

#### 3. 深度帶生成配額（每局）

| 深度帶 | Metal 數量 | Junk 數量 | Relic 數量 | Chest 數量 |
|--------|-----------|----------|-----------|-----------|
| 淺水區 | 12-18 | 4-8 | 0 | 0 |
| 中水區 | 8-12 | 2-5 | 0-1 | 0-1 |
| 深水區 | 5-8 | 1-3 | 1-2 | 0-1 |
| **全局總計** | **25-38** | **7-16** | **1-3** | **0-2** |

- 每局 Relic 總數：1-3 個（至少 1 個保底，確保 Roguelite 升級有機會觸發）
- 每局 Chest 總數：0-2 個（不保底，Chest 是意外驚喜）
- 數量範圍內使用 `randi_range(min, max)` 確定確切值

#### 4. 深度帶內稀有度加權抽選

每個深度帶內生成 Metal 物件時，依加權機率選擇稀有度：

| 深度帶 | COMMON | UNCOMMON | RARE | EPIC |
|--------|--------|---------|------|------|
| 淺水區 | 70% | 25% | 5% | 0% |
| 中水區 | 40% | 40% | 18% | 2% |
| 深水區 | 10% | 30% | 45% | 15% |

加權抽選演算法（Godot 實作）：

```gdscript
func weighted_rarity_pick(weights: Array[float]) -> int:
    var total = weights.reduce(func(a, b): return a + b, 0.0)
    var roll = randf() * total
    var cumulative = 0.0
    for i in range(weights.size()):
        cumulative += weights[i]
        if roll <= cumulative:
            return i
    return weights.size() - 1
```

#### 5. X 座標隨機分佈

每個物件的 X 座標從允許範圍內隨機選取，並套用最小間距約束：

```
spawn_x = randi_range(spawn_x_min, spawn_x_max)
```

- `spawn_x_min` = 50 px（距左牆壁）
- `spawn_x_max` = 場景寬度 - 50 px（距右牆壁）
- 最小物件間距 `min_object_spacing` = 60 px（避免視覺重疊）

若隨機位置與已放置物件衝突（間距不足），最多重試 `max_placement_retries` = 10 次，若仍失敗則跳過該物件（不強制填充）。

#### 6. Y 座標隨機分佈

在深度帶的 Y 範圍內隨機選取，避免物件整齊排列：

```
spawn_y = randi_range(zone_y_min + edge_margin, zone_y_max - edge_margin)
```

- `edge_margin` = 40 px（避免物件生成在深度帶邊緣，讓邊界過渡自然）

#### 7. 每局種子（Roguelite 隨機性）

每局開始時使用 `RandomNumberGenerator` 以當前時間戳記為種子：

```gdscript
var rng = RandomNumberGenerator.new()
rng.randomize()  # 以系統時間為種子
```

此確保每局生成結果不同，且玩家無法預測（Pillar 3）。

### States and Transitions

物資生成系統為一次性執行系統，無持續狀態機：

| 狀態 | 說明 | 轉換 |
|------|------|------|
| **WAITING** | 等待 `round_started` 信號 | 收到信號 → SPAWNING |
| **SPAWNING** | 批次生成所有物件 | 生成完畢 → IDLE |
| **IDLE** | 物件已在場景中，系統不再介入 | 收到 `round_ended` 信號 → CLEANUP |
| **CLEANUP** | 移除所有場景中的物件節點 | 完成 → WAITING |

### Interactions with Other Systems

| 系統 | 方向 | 數據流 |
|------|------|--------|
| **物資資料庫** | → 讀取 | 查詢可在此深度帶生成的 ItemData 列表（依 depth_min/depth_max 篩選） |
| **回合管理器** | → 讀取 | 監聽 `round_started` 觸發生成；監聽 `round_ended` 觸發清理 |
| **回合管理器** | ← 輸出 | 發出 `spawn_completed` 告知生成結束，回合可正式開始 |
| **物件吸附系統** | ← 輸出 | 生成的物件節點包含 Area2D，供吸附系統偵測 |
| **鏡頭系統** | ← 輸出 | 地圖範圍（場景寬高）由此系統的生成邊界定義 |

## Formulas

### 深度帶稀有度加權機率

加權選取時，以百分比作為權重：

```
roll = randf() * 100.0
if roll < w_COMMON: pick COMMON
elif roll < w_COMMON + w_UNCOMMON: pick UNCOMMON
elif roll < w_COMMON + w_UNCOMMON + w_RARE: pick RARE
else: pick EPIC
```

**淺水區範例計算**（weights: COMMON=70, UNCOMMON=25, RARE=5, EPIC=0）：
- roll = 82.3 → 82.3 >= 95（COMMON + UNCOMMON = 95）? 否 → 82.3 >= 70? 是 → **UNCOMMON**
- roll = 97.1 → 97.1 >= 95? 是 → **RARE**（5% 機率觸發）

### 物件數量上限驗證

```
total_items_per_round = metal_count + junk_count + relic_count + chest_count
```

| Variable | Min | Max | 說明 |
|----------|-----|-----|------|
| `total_items_per_round` | 33 | 59 | 場上物件總數參考值 |
| 每局下潛次數估算 | 4 | 6 | 4 分鐘內 30-60 秒一次下潛 |
| 每次撈取期望值 | 2.5 | 4.0 | 考慮 Junk 干擾 |
| 期望總撈取量 | 10 | 24 | 遠小於生成數，確保每局不會「清空」 |

> 設計意圖：物資總量是期望撈取量的 2-3 倍，玩家永遠感覺「還有更多」，但時間不允許全部撈完，形成取捨壓力（Pillar 2：4 分鐘完整體驗）。

### 最小間距衝突檢查

```gdscript
func has_spacing_conflict(candidate_pos: Vector2, placed_positions: Array[Vector2]) -> bool:
    for pos in placed_positions:
        if candidate_pos.distance_to(pos) < min_object_spacing:
            return true
    return false
```

| Variable | Default | Range |
|----------|---------|-------|
| `min_object_spacing` | 60 px | 40-100 |
| `max_placement_retries` | 10 | 5-20 |

## Edge Cases

| Edge Case | Resolution |
|-----------|-----------|
| 深度帶可用 ItemData 不足（沒有符合稀有度的物件定義） | 降一個稀有度重新選取。若 COMMON 也無匹配，跳過此物件（不強制生成） |
| X 座標重試 10 次後仍衝突 | 跳過此物件，不強制生成。回合仍正常進行（物件總數可能略低於下限） |
| `relic_count` 計算為 0（隨機結果所有帶都沒有 Relic） | 全局保底：若生成結束後 `total_relics == 0`，在中水區強制補生成 1 個最低稀有度 Relic |
| 場景寬度不足以容納最大物件數（理論過密） | `min_object_spacing` 確保最大密度下也有間隔；若仍無法放置則跳過。不縮小 spacing |
| 回合中物件被吸附後場景中剩餘物件為零 | 不補充物件（一次性生成）。回合計時繼續，玩家繼續下潛但空載而返 |
| CLEANUP 時仍有物件被磁鐵 attached（回合強制結束）| 只清理 WorldContainer 下的「未被吸附」物件，附著在磁鐵上的物件由回合管理器的 CHECK 流程處理 |
| 兩個 Relic 生成在同一個 X 位置附近（視覺重疊）| 最小間距約束適用於所有物件類別，包含 Relic |

## Dependencies

### Upstream（此系統依賴的系統）

- **物資資料庫** (hard) — 無物件定義無法進行任何生成；讀取 `ItemData.depth_min`、`ItemData.depth_max`、`ItemData.rarity`、`ItemData.category`
- **回合管理器** (hard) — 依賴 `round_started` 和 `round_ended` 信號控制生成和清理時機

### Downstream（依賴此系統的系統）

- **物件吸附系統** (hard) — 吸附系統偵測的物件由本系統生成至場景
- **鏡頭系統** (soft) — 地圖可視範圍的下限（max_depth = 2000 px）由生成邊界決定
- **回合管理器** (soft) — 依賴 `spawn_completed` 信號確認場景就緒

## Tuning Knobs

| Knob | Default | Safe Range | Affects | Too High | Too Low |
|------|---------|-----------|---------|----------|---------|
| `shallow_metal_count` | 12-18 | 8-25 | 淺水區金屬密度 | 早期太容易撈滿，減少深水探索動力 | 淺水區太空曠，玩家無事可做 |
| `deep_relic_count` | 1-2 | 0-3 | 每局 Relic 總量（主要在深水） | Roguelite 升級過於頻繁，稀有感下降 | 玩家可能整局未觸發升級 |
| `chest_per_round` | 0-2 | 0-3 | 每局 Chest 數量 | 風險/獎勵選擇泛濫 | Chest 如傳說般稀少，驚喜感受損 |
| `junk_ratio_shallow` | 25% | 10-40% | 淺水區 Junk 佔比 | 玩家常常空載而返，挫折感高 | 淺水區太簡單，無策略選擇 |
| `deep_epic_weight` | 15% | 5-25% | 深水區 EPIC 出現機率 | 深水區每局必有 EPIC，稀有感消失 | 深水探索無足夠獎勵誘因 |
| `min_object_spacing` | 60 px | 40-100 | 物件之間的最小間距 | 場景太空曠，物件分散難以撈取 | 物件重疊，視覺混亂、吸附判定衝突 |
| `max_placement_retries` | 10 | 5-20 | 位置衝突重試上限 | 生成時間過長（效能問題） | 太快放棄，物件生成數量不足 |

## Acceptance Criteria

1. **AC-01**: 每局生成結束後，物件分佈符合深度帶規則：淺水區無 Relic/Chest，深水區 EPIC 機率高於淺水區
2. **AC-02**: 每局至少生成 1 個 Relic（保底機制驗證）
3. **AC-03**: 使用不同隨機種子執行 5 局，每局物件的 X/Y 分佈肉眼可見不同
4. **AC-04**: 相鄰物件間距不低於 `min_object_spacing`（60 px）
5. **AC-05**: 生成完成後發出 `spawn_completed` 信號，回合管理器才允許玩家操作
6. **AC-06**: 回合結束後 CLEANUP 正確移除所有 WorldContainer 下的物件節點，無記憶體洩漏
7. **AC-07**: 深水區加權稀有度抽選在 1000 次模擬中，RARE + EPIC 合計佔比在 55-65% 範圍內（公式驗證）
8. **AC-08**: 生成總耗時不超過 200ms（手機效能標準，生成在載入畫面或淡入動畫期間完成）

## Open Questions

1. **物件生成位置可見性**: 是否在下潛前顯示海底輪廓（暗示有東西但模糊），還是完全未知？後者探索感更強，但前者策略感更強。
2. **Chest 深度固定**: Chest 是否應固定只生成在深水區？目前設計允許中水區也有 Chest，但深水區機率更高。
3. **新海域物件表**: Vertical Slice 後引入第二海域時，物件表是獨立集合還是累加？目前設計為獨立集合。
4. **物件視覺分層**: 海床是否有前景/背景分層？若有，物件生成是否需要考慮 Z-index 層？待美術方向確定。
