# 物資資料庫 (Item Database)

> **Status**: In Design
> **Author**: user + agents
> **Last Updated**: 2026-03-25
> **Implements Pillar**: 每局都不一樣 / 一次下潛的滿足感

## Overview

物資資料庫是定義遊戲中所有可撈取/可互動海底物件屬性的數據系統。它為磁鐵狀態機、經濟系統、物資生成系統提供統一的數據基礎。物件分為四大類：普通金屬（核心收入）、稀有遺物（觸發 Roguelite 升級）、障礙物（石頭/垃圾，佔用吸附槽位但無價值）、寶箱（高風險高回報的特殊物件）。每個物件擁有價值、重量、稀有度等屬性，其中重量直接影響磁鐵回收速度，創造「抓大物 vs 多抓小物」的核心策略選擇。

玩家不直接操作此系統 — 它是基礎設施層，為其他系統提供數據查詢。

## Player Fantasy

玩家的幻想不在於「資料庫」本身，而在於它創造的**多樣性和驚喜感**。每次磁鐵沉入水底，海床上散落著各式各樣的物件 — 生鏽的鐵釘、沉船的銅錠、神秘發光的遺物、甚至可能是一個寶箱。「你永遠不知道這次會撈到什麼」— 這就是此系統服務的情感。

服務 Pillar：**每局都不一樣**（物資多樣性和隨機分佈）+ **一次下潛的滿足感**（物件的價值差異讓每次撈取都有「判定」時刻）。

## Detailed Design

### Core Rules

#### 物件類別

| 類別 | 功能 | 範例 | 說明 |
|------|------|------|------|
| **Metal (金屬)** | 核心收入來源，兌換金錢 | 鐵釘、銅管、銀錠、金塊 | 最常見，價值隨稀有度遞增 |
| **Relic (遺物)** | 觸發 Roguelite 三選一升級 | 古代羅盤、深海王冠 | 稀有，每局 1-3 個 |
| **Junk (金屬垃圾)** | 佔用吸附槽但價值極低 | 空鐵罐、生鏽鐵片、彎釘子 | 干擾策略，因為磁鐵會吸附所有金屬 |
| **Chest (寶箱)** | 高重量但包含隨機高價值獎勵 | 鐵皮箱、沉船保險箱 | 高風險高回報：重量大拖慢回收 |

> 設計原則：因為是「磁鐵」，所有可吸附物件都是金屬材質。Junk 不是石頭或塑膠，而是低價值的金屬垃圾 — 磁鐵無法區分有價值和無價值的金屬，這就是策略所在。

#### 物件屬性結構

```gdscript
class_name ItemData extends Resource

@export var id: String             # 唯一識別碼 (e.g., "metal_iron_nail")
@export var display_name: String   # 顯示名稱
@export var category: Category     # METAL / RELIC / JUNK / CHEST
@export var value: int             # 金錢價值 (Junk = 0-2, Metal = 5-100+)
@export var weight: float          # 重量 (0.5-5.0)，影響回收速度
@export var rarity: Rarity         # COMMON / UNCOMMON / RARE / EPIC
@export var size: Vector2          # 碰撞體/視覺尺寸
@export var sprite: Texture2D      # 像素精靈圖
@export var depth_min: float       # 最淺出現深度
@export var depth_max: float       # 最深出現深度

enum Category { METAL, RELIC, JUNK, CHEST }
enum Rarity { COMMON, UNCOMMON, RARE, EPIC }
```

#### 稀有度分佈

| Rarity | 顏色編碼 | 典型 Value 範圍 | 典型 Weight 範圍 | 出現機率（基準） |
|--------|---------|----------------|-----------------|----------------|
| COMMON | 白色 | 5-15 | 0.5-1.5 | 50% |
| UNCOMMON | 綠色 | 15-40 | 1.0-2.5 | 30% |
| RARE | 藍色 | 40-80 | 2.0-3.5 | 15% |
| EPIC | 紫色 | 80-150+ | 3.0-5.0 | 5% |

> Junk 物件固定為 COMMON 稀有度。Relic 稀有度為 RARE 或 EPIC。Chest 稀有度為 UNCOMMON-EPIC。

#### 深度規則

物件只出現在其 `depth_min` ~ `depth_max` 範圍內。更深 = 更高價值但更難到達。

| 深度帶 | 範圍 (px) | 主要物件 |
|--------|----------|---------|
| 淺水區 | 800-1200 | COMMON Metal, Junk |
| 中水區 | 1200-1600 | UNCOMMON Metal, 少量 Relic |
| 深水區 | 1600-2000 | RARE/EPIC Metal, Chest, Relic |

### States and Transitions

物資資料庫為純數據系統，無運行時狀態機。物件在場景中的狀態由其他系統管理：

| 物件場景狀態 | 管理者 | 說明 |
|-------------|--------|------|
| **Spawned (已生成)** | 物資生成系統 | 物件在海底，等待被吸附 |
| **Attached (已吸附)** | 物件吸附系統 | 物件已被磁鐵吸附 |
| **Retrieved (已回收)** | 回合管理器 | 物件到達水面，進入兌換流程 |
| **Consumed (已消耗)** | 經濟系統 | 物件兌換為金錢或觸發效果 |

### Interactions with Other Systems

| 系統 | 方向 | 數據流 |
|------|------|--------|
| **物資生成系統** | → 讀取 | 查詢物件定義，按深度和稀有度生成實例 |
| **磁鐵狀態機** | → 讀取 | SINKING 時偵測可吸附物件（`magnetic == true`） |
| **物件吸附系統** | → 讀取 | 讀取 weight 計算回收速度減緩量 |
| **經濟系統** | → 讀取 | 讀取 value 計算兌換金額；讀取 category 判斷是否觸發 Relic 效果 |
| **遺物掉落表** | → 讀取 | 查詢 Relic 類別物件的可用池 |
| **HUD** | → 讀取 | 顯示物件名稱、稀有度顏色、價值 |

## Formulas

### 回收速度減緩公式

磁鐵回收時的向上速度受吸附物件的總重量影響：

```
retrieve_speed = base_retrieve_speed / (1 + total_weight * weight_drag_factor)
```

| Variable | Definition | Default | Range |
|----------|-----------|---------|-------|
| `base_retrieve_speed` | 無負重時的回收速度 (px/s) | 300 | 200-500 |
| `total_weight` | 所有吸附物件的 weight 總和 | — | 0-25 |
| `weight_drag_factor` | 重量對速度的影響係數 | 0.15 | 0.05-0.3 |

**範例計算**:
- 吸附 2 個 COMMON 鐵釘 (weight 0.5 each): speed = 300 / (1 + 1.0 × 0.15) = 261 px/s（略慢）
- 吸附 1 個 EPIC 金塊 (weight 4.0): speed = 300 / (1 + 4.0 × 0.15) = 188 px/s（明顯慢）
- 吸附 1 個 Chest (weight 5.0) + 2 個 Metal (weight 2.0): speed = 300 / (1 + 9.0 × 0.15) = 130 px/s（很慢）

### 物件價值公式（用於程序生成變體）

```
final_value = base_value * rarity_multiplier * depth_bonus
```

| Variable | Definition | Values |
|----------|-----------|--------|
| `base_value` | 物件基礎價值 | 由 ItemData 定義 |
| `rarity_multiplier` | COMMON=1.0, UNCOMMON=1.5, RARE=2.5, EPIC=4.0 |
| `depth_bonus` | 1.0 + (depth - 800) / 2400 | 1.0 ~ 1.5 |

## Edge Cases

| Edge Case | Resolution |
|-----------|-----------|
| 磁鐵吸附數量達到上限時碰到新物件 | 忽略新物件，不吸附。視覺提示（磁鐵閃爍紅色） |
| 磁鐵同時碰到多個物件 | 按距離排序，優先吸附最近的，直到達到上限 |
| Chest 的隨機獎勵結果為 0 | 設定最低保底值 = 20（不能比普通 UNCOMMON 差） |
| weight 總和超過 25（理論最大值） | 使用 clamp 限制，回收速度不低於 base × 0.2 |
| 所有物件被撈完（場上為空） | 物資生成系統負責處理：提前補充或結束回合 |
| Relic 觸發但 Roguelite 升級池已空 | 改為給予金錢獎勵（value × 3） |

## Dependencies

### Upstream (this system depends on)
- **無** — 物資資料庫是 Foundation 層，無上游依賴

### Downstream (depends on this system)
- **物資生成系統** (hard) — 無物件定義無法生成
- **磁鐵狀態機** (hard) — SINKING 偵測需要知道哪些物件可吸附
- **經濟系統** (hard) — 兌換需要 value 和 category 數據
- **物件吸附系統** (hard) — 回收速度需要 weight 數據
- **遺物掉落表** (soft) — Vertical Slice 才需要，MVP 可 hardcode
- **HUD** (soft) — 顯示資訊用，非核心功能

## Tuning Knobs

| Knob | Default | Safe Range | Affects | Too High | Too Low |
|------|---------|-----------|---------|----------|---------|
| `weight_drag_factor` | 0.15 | 0.05-0.3 | 回收速度減緩程度 | 重物幾乎無法回收 | 重量無意義 |
| `rarity_spawn_rates` | 50/30/15/5 | — | 各稀有度出現比例 | EPIC 太常見 | 回合無聊 |
| `junk_ratio` | 20% | 10-35% | 場上 Junk 佔比 | 太多干擾，挫折感 | 無策略選擇 |
| `relic_per_round` | 1-2 | 0-3 | 每局 Relic 數量 | Roguelite 升級太頻繁 | 升級無存在感 |
| `chest_per_round` | 0-1 | 0-2 | 每局 Chest 數量 | 風險選擇太多 | 缺少驚喜 |
| `depth_bonus_scale` | 0.5 | 0.2-1.0 | 深度對價值的加成 | 淺水區無價值 | 深水區無動力 |
| `max_attach_count` | 5 | 3-8 | 磁鐵最大吸附數量 | 一次撈太多，回合太短 | 每次下潛太少 |

## Visual/Audio Requirements

- 每種稀有度有對應的顏色光暈（COMMON 無, UNCOMMON 綠, RARE 藍, EPIC 紫）
- Relic 物件在海底有微弱脈動發光動畫
- Chest 物件有搖晃/微動的 idle 動畫
- 吸附瞬間的 SFX 按稀有度分級（越稀有越明顯的音效）

## UI Requirements

- 物件被吸附時顯示浮動 name tag + value 數字
- 稀有度顏色在 HUD 的已吸附物列表中體現
- Chest 開啟時有簡短的結果展示動畫

## Acceptance Criteria

1. **AC-01**: ItemData Resource 可在 Godot Editor 中建立和編輯所有欄位
2. **AC-02**: 至少定義 5 種 Metal（各稀有度至少 1 種）、2 種 Junk、1 種 Relic、1 種 Chest 用於 MVP
3. **AC-03**: 物資生成系統可根據 depth_min/depth_max 正確篩選物件
4. **AC-04**: 經濟系統可讀取 value 並正確計算兌換金額
5. **AC-05**: 回收速度公式正確運作：吸附重物時回收明顯變慢
6. **AC-06**: 稀有度顏色編碼在場景和 HUD 中一致
7. **AC-07**: max_attach_count 達到上限時，新物件不被吸附並有視覺提示

## Open Questions

1. Chest 開啟是即時結算還是回合結算時才開？— 待磁鐵狀態機 GDD 確定
2. 是否需要「不可磁吸」的物件作為環境裝飾？— 待美術方向確定
3. 新海域的物件表是獨立還是累加？（海域 2 是否包含海域 1 的物件）— 待物資生成系統 GDD 確定
