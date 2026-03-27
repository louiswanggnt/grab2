# HUD 系統 (HUD System)

> **Status**: In Design
> **Author**: user + agents
> **Last Updated**: 2026-03-25
> **Implements Pillar**: 4 分鐘就是一個完整體驗 / 一次下潛的滿足感

## Overview

HUD 系統是遊戲中所有即時資訊顯示的集合。它在遊玩過程中顯示倒數計時器、當前金錢餘額、已吸附物件數量/上限，並在回合結束時切換為結算畫面，在 CHECK 觸發 Relic 時顯示 Roguelite 三選一升級介面。HUD 是純呈現層（Presentation Layer）— 它只讀取其他系統的數據並顯示，不包含任何遊戲邏輯。HUD 針對單手直向手機操作設計，所有互動元素放置於拇指可及的螢幕下半部。

## Player Fantasy

「我眼角瞥一下計時器 — 還有 40 秒。磁鐵上已經掛了 4 個東西，一看圖示就知道有一個發光的 Relic。我知道情況，我能做決定。」

目標 MDA 美學：**Submission（資訊清晰帶來的安心感）**— HUD 讓玩家始終清楚自己的狀態，降低認知負擔。**Challenge（壓力設計）**— 計時器的視覺變化（最後 30 秒變紅）在不造成焦慮的前提下增加緊迫感。

## Detailed Design

### Core Rules

#### 1. HUD 元素列表（遊玩中）

| 元素 | 位置 | 說明 | 數據來源 |
|------|------|------|---------|
| 倒數計時器 | 螢幕頂部中央 | MM:SS 格式，最後 30 秒變紅並輕微放大 | RoundTimer.time_remaining |
| 當前金錢 | 螢幕頂部左側 | $ 符號 + 整數值 | EconomySystem.total_money |
| 吸附計數器 | 螢幕右側中央（垂直）| 「X / Y」格式，X=已吸附，Y=最大值 | ObjectAttachment.attached_count / max_attach_count |
| 吸附物件圖示列 | 吸附計數器下方 | 已吸附物件的小圖示（依稀有度顯示顏色） | ObjectAttachment.attached_items |
| 深度指示器（選填）| 螢幕左側中央 | 只在 SINKING/RETRIEVING 時顯示當前深度（m 或 px） | CameraSystem.current_depth |

#### 2. 倒數計時器行為

**正常狀態**（time_remaining > 30s）：
- 白色文字
- 字體大小：標準（32pt 邏輯大小）
- 格式：`MM:SS`（例：`03:45`）

**緊急狀態**（time_remaining <= 30s）：
- 紅色文字（`#FF4444`）
- 字體大小：放大（38pt，約 1.2× 倍率）
- 輕微脈動縮放動畫：Scale 在 1.0-1.1 之間，週期 1.0s

**CHECK 暫停期間**：
- 計時器數字靜止不動（因 RoundTimer 已暫停）
- 加上靜止視覺標記（例如計時器顯示時鐘暫停圖示 ⏸）

**時間到（EXPIRED）**：
- 顯示 `00:00`
- 閃爍一次（不循環閃爍，只閃一下作為結束信號）

#### 3. 吸附計數器行為

- 格式：`attached_count / max_attach_count`，例如 `3 / 5`
- 滿載（`attached_count == max_attach_count`）時：計數器文字變橘紅色（`#FF6600`），持續顯示（提醒不能再吸附）
- IDLE 和 CHECK 狀態時，計數器仍顯示（不隱藏），顯示上一次結果直到 CHECK 完成後歸零

#### 4. 吸附物件圖示列

- 每個吸附物件顯示一個小圖示（24×24 px）
- 圖示使用物件的 sprite，背景顏色依稀有度：COMMON=白色邊框、UNCOMMON=綠色邊框、RARE=藍色邊框、EPIC=紫色邊框
- 圖示從上到下依序排列（新吸附的物件加在最下方）
- 超過 5 個（升級擴展後的 max_attach_count）時，自動縮小間距，最多顯示 8 個

#### 5. Roguelite 三選一升級介面

在 CHECK 狀態處理 Relic 物件時觸發，覆蓋於 HUD 上層：

**佈局**：
- 全螢幕半透明遮罩（Alpha 0.8 黑色）
- 標題：「選擇升級」（32pt 白色，頂部）
- 三個升級卡片，垂直排列，手機直向螢幕友好
- 每張卡片包含：
  - 升級名稱（20pt 粗體）
  - 升級效果說明（16pt，單行）
  - 升級圖示（48×48 px）
  - 卡片邊框顏色依升級稀有度

**卡片點擊**：
- 玩家點擊任一卡片後，卡片播放選中動畫（縮放閃光 0.3s）
- 動畫完成後，升級介面淡出（0.2s）
- 同時呼叫升級系統套用效果，繼續 CHECK 流程

**超時保護**：
- 若玩家 15 秒未選擇（例如放下手機），自動選擇隨機卡片
- 顯示 15 秒倒數小計時（在選擇介面的底部）

#### 6. 結算畫面（SUMMARY）

由回合管理器觸發，取代遊玩中 HUD：

**顯示項目**（由上到下）：

| 項目 | 格式 | 範例 |
|------|------|------|
| 標題 | 大標 | 「回合結束」 |
| 本局總收益 | `+$XXX` 金色數字 | `+$142` |
| 下潛次數 | `X 次下潛` | `5 次下潛` |
| 最高單次收益 | `最佳下潛：$XX` | `最佳下潛：$58` |
| 收益評級 | 「豐收 / 不錯 / 繼續努力」 | 「不錯」 |
| 繼續按鈕 | 螢幕底部 CTA 按鈕 | 「再玩一局」 |
| 返回主選單 | 文字按鈕（小） | 「返回大廳」 |

**數字浮現動畫**：
- 各統計數字依序淡入（每項間隔 0.3s）
- 總收益使用計數器動畫（從 0 計數到 final_value，0.8s）

### States and Transitions

HUD 系統根據遊戲狀態切換顯示模式：

| 遊戲狀態 | HUD 模式 | 顯示內容 |
|---------|---------|---------|
| SPAWNING | 隱藏 / 載入畫面 | 僅顯示載入動畫 |
| PLAYING（IDLE）| 標準 HUD | 全部常駐元素 |
| PLAYING（SINKING）| 標準 HUD + 深度指示 | 加入深度指示器 |
| PLAYING（RETRIEVING）| 標準 HUD | 標準元素（吸附數量已更新） |
| PLAYING（CHECK）| 標準 HUD + 升級介面（若有 Relic）| 升級介面蓋在 HUD 上 |
| ENDING | 標準 HUD（計時器顯示 00:00）| 鎖定輸入的 HUD |
| SUMMARY | 結算畫面 | 完全切換，遊玩 HUD 隱藏 |

### Interactions with Other Systems

| 系統 | 方向 | 數據流 |
|------|------|--------|
| **回合計時系統** | → 讀取 | 讀取 `time_remaining`（每幀）和 `is_urgent`（布林） |
| **回合計時系統** | → 監聽 | 監聽 `time_expired` 觸發計時器最後的閃爍效果 |
| **經濟系統** | → 讀取 | 讀取 `total_money` 顯示當前金錢（每幀或每次 CHECK 後更新） |
| **物件吸附系統** | → 讀取 | 讀取 `attached_count`、`max_attach_count`、`attached_items` 列表 |
| **物件吸附系統** | → 監聽 | 監聽 `attachment_full` 信號觸發滿載提示 |
| **回合管理器** | → 讀取 | 讀取回合狀態（SPAWNING/PLAYING/ENDING/SUMMARY）控制 HUD 模式切換 |
| **回合管理器** | → 監聽 | 監聽 `round_summary_data` 接收結算數據顯示結算畫面 |
| **磁鐵狀態機** | → 監聽 | 監聽 `state_changed` 以顯示/隱藏深度指示器 |
| **鏡頭系統** | → 讀取 | 讀取 `current_depth` 顯示深度指示器（選填元素） |

## Formulas

### 倒數計時器格式

```gdscript
func format_time(seconds: float) -> String:
    var minutes = int(seconds) / 60
    var secs = int(seconds) % 60
    return "%02d:%02d" % [minutes, secs]
```

**範例**：
- time_remaining = 145.7 → `02:25`
- time_remaining = 7.3 → `00:07`
- time_remaining = 0.0 → `00:00`

### 計時器緊急脈動縮放

```gdscript
func get_pulse_scale(time: float) -> float:
    return 1.0 + 0.1 * sin(time * TAU)  # TAU = 2*PI，週期 1.0s
```

| Variable | Value | 說明 |
|----------|-------|------|
| 基礎大小 | 1.0 | 正常縮放 |
| 最大脈動 | 1.1 | 最大縮放（+10%） |
| 週期 | 1.0s | sin 完整週期 |
| 觸發條件 | `is_urgent == true`（time <= 30s） | — |

### 結算數字計數器動畫

```gdscript
func animate_counter(target: int, duration: float) -> void:
    var elapsed = 0.0
    while elapsed < duration:
        elapsed += get_process_delta_time()
        var t = elapsed / duration
        display_value = int(lerp(0.0, float(target), ease(t, -2.0)))
        await get_tree().process_frame
    display_value = target
```

- `ease(-2.0)` 產生先快後慢的計數效果（數字快速上升後緩慢到達終值）
- 總動畫時間：0.8s

## Edge Cases

| Edge Case | Resolution |
|-----------|-----------|
| `time_remaining` 在更新週期內跳過 0（浮點誤差） | 使用 `time_remaining <= 0` 作為判斷條件，不依賴恰好等於 0 |
| `attached_count` 因 bug 超過 `max_attach_count` | 顯示實際值（不 clamp）；加入 assert 在開發期間捕捉此 bug |
| Roguelite 升級池為空時 Relic 兌換為金錢 | 升級介面不顯示，直接顯示金錢浮字效果（「+$XX」浮現）代替選卡 |
| 玩家在升級介面期間點擊螢幕其他區域 | 無效操作，介面不消失。玩家必須點擊卡片或等待超時 |
| 升級介面 15 秒超時自動選擇 | 隨機選一張卡片，播放選中動畫後繼續；LOG 記錄「auto-selected upgrade due to timeout」 |
| 結算畫面數字動畫期間玩家快速點擊繼續按鈕 | 動畫立即跳到終值，繼續按鈕保持可用（不鎖定按鈕） |
| `total_money` 超過 6 位數（99,999+）| 改用縮寫格式：`$100K`（超過 9999）。防止佈局溢出 |
| SINKING 期間吸附物件圖示快速變更（多個快速吸附）| 圖示列使用 tween 漸入動畫，快速吸附時新圖示排隊播放動畫，不跳過 |
| 手機螢幕尺寸極小（< 320px 寬）| 深度指示器（選填元素）自動隱藏；其他元素縮小至 85%，確保不重疊 |

## Dependencies

### Upstream（此系統依賴的系統）

- **回合計時系統** (hard) — `time_remaining`、`is_urgent`、`time_expired` 信號
- **經濟系統** (hard) — `total_money` 數值
- **物件吸附系統** (hard) — `attached_count`、`max_attach_count`、`attached_items`、`attachment_full` 信號
- **回合管理器** (hard) — 回合狀態、`round_summary_data` 結算數據
- **磁鐵狀態機** (soft) — `state_changed` 信號（深度指示器顯示控制）
- **鏡頭系統** (soft) — `current_depth`（深度指示器數值）

### Downstream（依賴此系統的系統）

- **教學系統** (soft) — Alpha 階段，教學高亮 HUD 元素（未來）
- **無** — HUD 是 Presentation Layer 末端，無下游功能系統

## Tuning Knobs

| Knob | Default | Safe Range | Affects | Too High | Too Low |
|------|---------|-----------|---------|----------|---------|
| `urgent_display_threshold` | 30s | 15-60 | 計時器變紅的觸發時間 | 玩家長時間處於緊張視覺 | 緊迫感出現太晚，玩家無準備 |
| `pulse_amplitude` | 0.1（+10%） | 0.05-0.25 | 緊急計時器的脈動幅度 | 過於顯眼，分散注意力 | 脈動不明顯 |
| `pulse_period` | 1.0s | 0.5-2.0 | 緊急計時器的脈動週期 | 太慢，不像「緊急」 | 太快，視覺疲勞 |
| `upgrade_auto_select_timeout` | 15s | 10-30 | 升級介面等待超時 | 玩家放下手機後等待太長才自動選 | 玩家思考時間不足就被自動選 |
| `summary_counter_duration` | 0.8s | 0.3-2.0 | 結算數字計數動畫時長 | 結算過程感覺拖泥帶水 | 數字瞬間出現，無成就感 |
| `summary_item_stagger` | 0.3s | 0.1-0.6 | 結算各統計項目的出現間隔 | 結算節奏過慢，玩家等待焦急 | 所有數字同時出現，失去節奏感 |
| `icon_size` | 24 px | 18-32 | 吸附物件小圖示大小 | 圖示佔據太多螢幕空間 | 圖示太小，稀有度顏色看不清 |

## Acceptance Criteria

1. **AC-01**: 倒數計時器每秒更新一次，格式為 `MM:SS`，與 RoundTimer.time_remaining 誤差不超過 0.1 秒
2. **AC-02**: 計時器在 time_remaining <= 30s 時變紅並開始脈動縮放（Scale 在 1.0-1.1 之間，週期 1.0s）
3. **AC-03**: CHECK 狀態期間計時器顯示靜止（RoundTimer 暫停時數字不變動）
4. **AC-04**: 吸附計數器 `X / Y` 值與 ObjectAttachment 的數值實時一致；滿載時計數器變橘紅色
5. **AC-05**: 吸附物件圖示的稀有度邊框顏色與 item-database.md 定義一致（COMMON=白、UNCOMMON=綠、RARE=藍、EPIC=紫）
6. **AC-06**: Relic 觸發時，升級介面正確顯示 3 張卡片，點擊後動畫播放並正確呼叫升級系統
7. **AC-07**: 15 秒升級超時後，自動選擇並繼續遊戲，不卡住 CHECK 流程
8. **AC-08**: 結算畫面正確顯示 total_earnings、dive_count、best_dive_earnings，數值與回合管理器一致
9. **AC-09**: 結算數字計數動畫在 0.8s 內完成，最終值正確
10. **AC-10（體驗標準）**: 遊玩測試中，10 位測試者在遊玩 2 分鐘後，能不看說明正確說出「計時器在哪、金錢在哪、已吸附幾個物件」

## Open Questions

1. **深度指示器格式**: 顯示像素值（1340 px）還是虛構的海洋深度（-134m）？後者更有沉浸感，但需要換算係數。待美術/敘事方向決定。
2. **吸附物件圖示的顯示時機**: 是否在 IDLE 狀態下隱藏圖示列（顯示為空），還是一直顯示（包含上次下潛未清除的視覺）？目前設計為 CHECK 完成才清除，所以在 IDLE 時短暫期間仍顯示上一次的結果。
3. **金錢浮字**: 每次 CHECK 時，金錢增加的數值是否顯示浮字（`+$XX`）在 HUD 金錢顯示旁邊？這是很常見的回饋設計，建議加入，但待 UX 確認佈局不擁擠。
4. **結算評級圖示**: 「豐收/不錯/繼續努力」是否需要配合不同的視覺表情或圖示？待美術確認。
