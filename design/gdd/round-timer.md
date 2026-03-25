# 回合計時系統 (Round Timer)

> **Status**: In Design
> **Author**: user + agents
> **Last Updated**: 2026-03-25
> **Implements Pillar**: 4 分鐘就是一個完整體驗

## Overview

回合計時系統管理每局 4 分鐘的倒數計時。它為整局遊玩提供時間框架和節奏感，是 Pillar 2「4 分鐘完整體驗」的技術基礎。計時器發出信號驅動回合管理器的生命週期，並在 HUD 上顯示剩餘時間。

## Player Fantasy

時間壓力創造緊迫感 — 「還有 30 秒，要不要冒險再下潛一次？」。但時間不應讓人焦慮，而是提供明確的結束預期，讓碎片時間玩家安心。

## Detailed Design

### Core Rules

1. 回合時長固定為 `round_duration`（預設 240 秒 = 4 分鐘）
2. 計時器在第一次釋放磁鐵（IDLE → SINKING）時開始倒數
3. 計時器在以下情況暫停：
   - CHECK 狀態（兌換和選擇升級時不消耗時間）
   - 遊戲暫停
4. 最後 30 秒進入「緊急模式」— HUD 計時器變紅並放大
5. 時間歸零時，當前下潛立即進入強制回收（RETRIEVING），然後結算

### States and Transitions

| State | Description | Transition |
|-------|------------|-----------|
| **WAITING** | 回合開始前，等待玩家首次下潛 | 玩家釋放磁鐵 → RUNNING |
| **RUNNING** | 正常倒數中 | 進入 CHECK → PAUSED；時間歸零 → EXPIRED |
| **PAUSED** | CHECK 狀態或暫停時暫停 | 離開 CHECK → RUNNING |
| **EXPIRED** | 時間到 | 觸發回合結束信號 |

### Interactions with Other Systems

| 系統 | 方向 | 數據流 |
|------|------|--------|
| **磁鐵狀態機** | → 讀取 | 監聽狀態變化：IDLE→SINKING 啟動計時、進入/離開 CHECK 暫停/恢復 |
| **回合管理器** | ← 輸出 | 發出 `time_expired` 信號觸發回合結算 |
| **HUD** | ← 輸出 | 提供 `time_remaining` 和 `is_urgent` 給 HUD 顯示 |

## Formulas

```
time_remaining = round_duration - elapsed_active_time
is_urgent = time_remaining <= urgent_threshold
```

| Variable | Default | Range |
|----------|---------|-------|
| `round_duration` | 240s | 120-360s |
| `urgent_threshold` | 30s | 15-60s |

## Edge Cases

| Edge Case | Resolution |
|-----------|-----------|
| 玩家整局不釋放磁鐵 | 計時器一直在 WAITING，無時間限制（鼓勵玩家行動可通過 UI 提示） |
| 時間到時磁鐵正在 SINKING | 立即切換到 RETRIEVING 強制回收 |
| 時間到時正在 CHECK | 讓 CHECK 完成後再結算（不中斷選擇） |
| 時間到時磁鐵正在 RETRIEVING | 讓回收完成後結算（不丟失已吸附物資） |

## Dependencies

### Upstream
- **無** — Foundation 層

### Downstream
- **回合管理器** (hard) — 需要 time_expired 信號
- **HUD** (hard) — 顯示剩餘時間

## Tuning Knobs

| Knob | Default | Safe Range | Affects |
|------|---------|-----------|---------|
| `round_duration` | 240s | 120-360s | 回合時長。太短→下潛次數不足，太長→碎片時間不友好 |
| `urgent_threshold` | 30s | 15-60s | 緊急模式觸發時間。太早→一直緊張，太晚→無緊迫感 |
| `pause_during_check` | true | bool | CHECK 時是否暫停計時。false 會增加時間壓力 |

## Acceptance Criteria

1. **AC-01**: 計時器在首次釋放磁鐵時開始倒數
2. **AC-02**: CHECK 狀態期間計時器暫停
3. **AC-03**: 240 秒後 `time_expired` 信號正確發出
4. **AC-04**: 最後 30 秒 HUD 進入緊急模式
5. **AC-05**: 時間到時若磁鐵在水下，強制進入回收狀態

## Open Questions

1. 是否需要「加時」道具或遺物升級？— 待 Roguelite 升級系統設計時決定
