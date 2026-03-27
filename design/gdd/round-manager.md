# 回合管理器 (Round Manager)

> **Status**: In Design
> **Author**: user + agents
> **Last Updated**: 2026-03-25
> **Implements Pillar**: 4 分鐘就是一個完整體驗

## Overview

回合管理器管理一局遊戲的完整生命週期：從玩家進入遊戲場景，到 4 分鐘後時間到期，再到結算畫面展示本局成績。它是各系統的協調者（Orchestrator）而非實作者 — 它發出信號啟動物資生成、監聽計時器到期、協調強制回收流程、收集統計數據，最終呈現結算畫面。作為遊戲體驗的「容器」，回合管理器定義了每一局的完整弧線。

## Player Fantasy

「每局都有清晰的開始和結束。4 分鐘後，結算畫面告訴我這局賺了多少、下潛了幾次、最值錢的東西是什麼 — 讓我感覺這局的時間是有意義的。」

目標 MDA 美學：**Submission（沉浸結構）**— 清晰的回合結構讓玩家安心投入，知道什麼時候是「一個完整的結束」。**Achievement（成就感）**— 結算畫面的統計數字量化了這局的努力。

## Detailed Design

### Core Rules

#### 1. 回合狀態機

回合管理器維護獨立的回合生命週期狀態機：

```
INIT → SPAWNING → PLAYING → ENDING → SUMMARY → (下一局 → INIT)
```

#### 2. 狀態詳細定義

**INIT（初始化）**
- 回合進入時執行一次
- 重置所有本局統計數據（total_earnings、dive_count 等）
- 向物資生成系統發出 `round_started` 信號
- 立即切換到 SPAWNING

**SPAWNING（等待物資生成）**
- 等待物資生成系統回傳 `spawn_completed` 信號
- 在此期間顯示載入/淡入動畫
- 收到 `spawn_completed` → 切換到 PLAYING

**PLAYING（遊玩中）**
- 允許玩家操作磁鐵（磁鐵狀態機回到 IDLE，接受輸入）
- 開始計時（不由此系統直接驅動，透過允許 IDLE→SINKING 轉換讓 RoundTimer 自行啟動）
- 監聽 `time_expired` 信號（來自回合計時系統）
- 監聽 `check_completed` 信號（來自磁鐵狀態機），每次 CHECK 結束時更新統計
- 收到 `time_expired` → 切換到 ENDING

**ENDING（回合結束中）**
- 若磁鐵當前在水下（SINKING 或 RETRIEVING）：等待它完成自然的強制回收並通過 CHECK
- 若磁鐵已在水面（IDLE 或 CHECK）：等待當前 CHECK 完成
- 在此期間禁止玩家再次釋放磁鐵（鎖定 IDLE→SINKING 轉換）
- 所有待處理的 CHECK 完成後 → 切換到 SUMMARY

**SUMMARY（結算畫面）**
- 計算最終統計數據
- 將本局收益加入總金錢（呼叫 EconomySystem.add_earnings）
- 顯示結算 UI
- 等待玩家確認（點擊繼續）→ 切換到下一局 INIT 或返回主選單

#### 3. 下潛統計追蹤

PLAYING 期間，每次收到磁鐵狀態機的 `check_completed` 信號時更新：

```gdscript
func _on_check_completed(check_data: CheckData):
    dive_count += 1
    total_earnings += check_data.earnings
    if check_data.earnings > best_dive_earnings:
        best_dive_earnings = check_data.earnings
    dive_earnings_history.append(check_data.earnings)
```

CheckData 結構：

```gdscript
class_name CheckData
var earnings: int           # 本次 CHECK 獲得的金錢
var items_retrieved: Array  # 撈到的物件列表（含類別和稀有度）
var had_relic: bool         # 是否觸發了 Relic 升級
```

#### 4. 結算統計項目（SUMMARY）

| 統計項目 | 說明 | 計算方式 |
|---------|------|---------|
| `total_earnings` | 本局總收益 | 累加所有 CHECK 的 earnings |
| `dive_count` | 本局下潛次數 | 每次 CHECK 完成 +1 |
| `best_dive_earnings` | 最高單次下潛收益 | CHECK 記錄中的最大值 |
| `relic_count` | 本局觸發 Relic 次數 | 累加 had_relic == true 的次數 |
| `total_items_retrieved` | 本局總撈取物件數 | 所有 CHECK 的物件數量總和 |
| `average_earnings_per_dive` | 平均每次下潛收益 | total_earnings / dive_count（整數除法） |

#### 5. 強制回收協議（時間到期時）

時間到期時（收到 `time_expired`），磁鐵可能在任一狀態：

| 磁鐵狀態 | 回合管理器的處理 |
|---------|----------------|
| IDLE | 直接進入 ENDING，等待邏輯為「已無進行中的下潛」，立即可進 SUMMARY |
| SINKING | 向磁鐵狀態機發出 `force_retrieve` 信號，磁鐵切換至 RETRIEVING，回合管理器等待後續的 `check_completed` |
| RETRIEVING | 等待自然回收完成，不中斷。磁鐵繼續上升直到觸發 CHECK |
| CHECK | 不中斷 CHECK 流程。等待 `check_completed` 後才進入 SUMMARY |

> 核心原則：**不在 CHECK 過程中強制結束**。玩家辛苦撈到的物件，時間到了也應完整結算。這直接服務 Pillar 2 的「公平感」。

### States and Transitions

| From | To | Trigger | Guard |
|------|----|---------|-------|
| INIT | SPAWNING | 自動（INIT 完成） | — |
| SPAWNING | PLAYING | 收到 `spawn_completed` | — |
| PLAYING | ENDING | 收到 `time_expired` | — |
| ENDING | SUMMARY | 所有下潛完成（無進行中的 SINKING/RETRIEVING/CHECK） | 至少一次 `check_completed`（或 dive_count == 0 則直接允許） |
| SUMMARY | INIT | 玩家確認繼續 | — |
| SUMMARY | 主選單 | 玩家選擇退出 | — |

### Interactions with Other Systems

| 系統 | 方向 | 數據流 |
|------|------|--------|
| **回合計時系統** | → 讀取 | 監聽 `time_expired` 信號觸發 ENDING |
| **物資生成系統** | ← 輸出 | 發出 `round_started`；監聽 `spawn_completed` |
| **磁鐵狀態機** | → 讀取 | 監聽 `check_completed` 更新統計；發出 `force_retrieve` 信號（時間到且在水下） |
| **磁鐵狀態機** | ← 輸出 | ENDING 時鎖定 IDLE→SINKING 轉換（設定 `allow_new_dive = false`） |
| **經濟系統** | ← 輸出 | SUMMARY 時呼叫 `EconomySystem.add_earnings(total_earnings)` |
| **HUD 系統** | ← 輸出 | 提供當前回合狀態和統計數據，SUMMARY 時傳遞結算數據給結算 UI |

## Formulas

### 平均每次下潛收益

```
average_earnings_per_dive = total_earnings / max(dive_count, 1)
```

使用 `max(dive_count, 1)` 防止除以零（零次下潛時顯示 0）。

### 預期回合收益範圍（用於結算 UI 評級）

依據 economy-system.md 的預期收入估算：

| 階段 | 預期每局總收益 | 對應升級進度 |
|------|-------------|------------|
| 早期（無升級） | 60-100 | 0-2 項升級 |
| 中期（幾項升級） | 120-200 | 3-6 項升級 |
| 後期（接近滿級） | 200-350 | 7-10 項升級 |

結算評級（選填視覺設計，非核心規則）：

```
if total_earnings >= high_threshold: rating = "豐收"
elif total_earnings >= mid_threshold: rating = "不錯"
else: rating = "繼續努力"
```

| Variable | Default | 說明 |
|----------|---------|------|
| `high_threshold` | 150 | 超出此值顯示「豐收」 |
| `mid_threshold` | 80 | 超出此值顯示「不錯」 |

> 評級閾值應隨玩家升級進度動態調整（Vertical Slice 功能，MVP 可使用固定值）。

## Edge Cases

| Edge Case | Resolution |
|-----------|-----------|
| 玩家整局未釋放磁鐵（dive_count == 0） | 結算顯示 total_earnings = 0，dive_count = 0，average 顯示 0。不崩潰 |
| 時間到期時磁鐵在水下並已滿載 | 正常強制回收 → CHECK → 結算，確保滿載的物件不丟失 |
| SPAWNING 期間物資生成系統超時（> 500ms） | 等待最多 2 秒，若仍無 `spawn_completed` 則記錄錯誤並強制進入 PLAYING（降級處理） |
| SUMMARY 顯示期間玩家強制關閉遊戲 | 金錢由 `add_earnings` 呼叫後存入存檔；若在 SUMMARY 前崩潰則本局收益丟失（acceptable，與經濟系統設計一致） |
| dive_count 達到異常高值（> 20，理論不可能） | 只是統計值，無功能影響。可在開發期間加 assert 提醒 |
| ENDING 狀態等待超過 30 秒（極端情況：磁鐵卡在深水） | 強制觸發 SUMMARY（不等待）。此為保護機制，正常遊玩不應發生 |
| 玩家在 SUMMARY 期間收到 Relic 三選一 UI（理論不應發生） | ENDING 開始後，磁鐵狀態機的 CHECK 流程應在 SUMMARY 前完整處理所有 Relic。若發生則為 bug，LOG 錯誤並跳過升級 |

## Dependencies

### Upstream（此系統依賴的系統）

- **回合計時系統** (hard) — 依賴 `time_expired` 信號觸發 ENDING
- **磁鐵狀態機** (hard) — 依賴 `check_completed` 信號更新統計；依賴 `state_changed` 監控磁鐵是否在水下；發出 `force_retrieve` 信號
- **物資生成系統** (hard) — 依賴 `spawn_completed` 確認場景就緒
- **經濟系統** (hard) — 呼叫 `add_earnings()` 儲存本局收益

### Downstream（依賴此系統的系統）

- **物資生成系統** (hard) — 依賴 `round_started` 信號啟動生成
- **HUD 系統** (soft) — 依賴回合狀態和統計數據顯示 UI
- **教學系統** (soft) — Alpha 階段，依賴 `round_started` 觸發新手引導（未來）

## Tuning Knobs

| Knob | Default | Safe Range | Affects | Too High | Too Low |
|------|---------|-----------|---------|----------|---------|
| `high_threshold` | 150 | 80-300 | 「豐收」評級門檻 | 玩家幾乎達不到「豐收」，降低成就感 | 評級失去意義，每局都是豐收 |
| `mid_threshold` | 80 | 40-150 | 「不錯」評級門檻 | 大多數玩家只能得「繼續努力」 | 評級失去分層 |
| `ending_timeout` | 30s | 15-60 | ENDING 等待超時保護 | 磁鐵卡住時玩家等待太久 | 正常的最後一次下潛被強制中斷 |
| `spawn_timeout` | 2s | 1-5 | SPAWNING 等待超時 | 不影響遊玩，但異常等待影響體驗 | 物資生成還未完成就進入遊玩 |

## Acceptance Criteria

1. **AC-01**: 回合完整走完 INIT → SPAWNING → PLAYING → ENDING → SUMMARY 生命週期，無跳過或卡住
2. **AC-02**: `round_started` 信號在 INIT 完成後發出，`spawn_completed` 收到後才允許玩家操作
3. **AC-03**: `time_expired` 收到後，磁鐵若在 SINKING 狀態，正確轉入強制 RETRIEVING 並完成 CHECK
4. **AC-04**: `time_expired` 後，若磁鐵已在 IDLE 或正在 CHECK，ENDING 正確等待並不中斷 CHECK 流程
5. **AC-05**: ENDING 期間玩家無法再次釋放磁鐵（IDLE→SINKING 被鎖定）
6. **AC-06**: SUMMARY 顯示的 `total_earnings` 與所有 CHECK 的 earnings 總和一致（整合測試：5 次下潛後比對）
7. **AC-07**: `EconomySystem.add_earnings(total_earnings)` 在 SUMMARY 進入時正確呼叫，金錢正確增加
8. **AC-08**: dive_count 為 0 時，SUMMARY 不崩潰，顯示「0 次下潛，$0」
9. **AC-09（體驗標準）**: 10 局遊玩測試中，結算畫面呈現的數據（下潛次數、總收益）與玩家實際操作記憶相符，無錯誤統計

## Open Questions

1. **多局連續**: SUMMARY 的「再玩一局」是否重用同一場景（重新 INIT）還是重新載入場景？重用更快但需確保所有狀態正確重置。
2. **結算評級**: 評級（豐收/不錯/繼續努力）門檻是否應根據玩家當前升級等級動態調整？MVP 使用固定值，Vertical Slice 評估。
3. **歷史統計**: SUMMARY 是否需要顯示「與上局比較」或「個人最高紀錄」？MVP 不需要，後期考慮。
4. **Relic 升級的結算時機**: 目前 Relic 在 CHECK 狀態中即時觸發三選一升級。ENDING 時的 CHECK 也會觸發升級 UI，這是預期行為（確保不丟失 Relic），需在 UX 層確認流程順序是否直觀。
