# Grab2 — Session Handoff

> **Last Updated**: 2026-03-27
> **Current Phase**: Implementation — Phase A+B+C Complete（Bug 修復 + UI 完善 + 美術替換準備完成）

---

## Quick Context

**Grab2 是什麼？** 一款 2D 物理抓取 Roguelite 手機遊戲。玩家操控磁鐵沉入深海，在 4 分鐘內撈取金屬物資和稀有遺物，用收益升級裝備。

**Engine**: Godot 4.3 / GDScript / Pixel Art

---

## Current State

### Done
- [x] 初始原型（磁鐵抓取基本流程可運行）
- [x] 引擎配置（`/setup-engine` Godot 4.3）
- [x] 遊戲概念文件（`design/gdd/game-concept.md`）
- [x] 系統分解（`design/gdd/systems-index.md`）— 17 個系統
- [x] Foundation 層 GDD（3/3 完成）：
  - `design/gdd/item-database.md` — 物資資料庫
  - `design/gdd/touch-input.md` — 觸控輸入系統
  - `design/gdd/round-timer.md` — 回合計時系統
- [x] Bug 修復：CHECK 計時器到期路徑、移除舊 UI Label、Overlay 輸入阻擋
- [x] UI 完善：HUD 吸附計數器狀態顯示、回合結束淡入動畫、商店行寬適配
- [x] 美術替換準備：ASSET_MANIFEST.md、圖片自動載入（fallback 佔位符）、海洋深度漸層

### In Progress
- [x] Core 層 GDD（3/3 完成）：
  - `design/gdd/boat-controller.md` — 船控制器
  - `design/gdd/magnet-state-machine.md` — 磁鐵狀態機
  - `design/gdd/economy-system.md` — 經濟系統
- [ ] Feature 層 GDD（0/4）：物件吸附、物資生成、鏡頭、回合管理器
- [x] 程式碼資料夾結構 (`docs/architecture/folder-structure.md`)
- [x] Phase C：美術替換（圖片路徑 + 資產清單 + 自動載入 + 海洋漸層）

### Not Started (Ready to Start)
- [ ] MVP 實作（Foundation + Core 層 GDD 已就緒）
- [ ] 觸控操作適配
- [ ] 音效/視覺 juice
- [ ] 多海域內容

---

## Key Files

| File | Purpose |
|------|---------|
| `design/gdd/game-concept.md` | 遊戲概念文件（核心設計方向） |
| `design/gdd/systems-index.md` | 系統索引（17 系統、依賴圖、設計順序） |
| `docs/architecture/folder-structure.md` | 程式碼資料夾結構和遷移計劃 |
| `.claude/docs/technical-preferences.md` | 技術偏好（命名規範等） |
| `CLAUDE.md` | 專案主設定 |
| `docs/engine-reference/godot/VERSION.md` | 引擎版本參考 |
| `Main.gd` / `Boat.gd` / `Magnet.gd` / `Fish.gd` | 現有原型代碼 |
| `src/ui/hud.gd` / `src/ui/hud.tscn` | Phase 1 HUD 實裝（計時、金錢、附件顯示） |
| `src/ui/round_end_screen.gd` / `src/ui/round_end_screen.tscn` | 回合結束畫面（淡入動畫、收益摘要） |
| `src/ui/shop_panel.gd` / `src/ui/shop_panel.tscn` | 商店面板（行寬適配） |
| `src/magnet/magnet_state_machine.gd` | 磁鐵狀態機（CHECK 計時器到期路徑修復） |
| `src/economy/economy_system.gd` | 經濟系統 |
| `src/items/metal_object.gd` | 金屬物件邏輯（tier 圖片自動載入） |
| `src/main/round_stats.gd` | 回合統計資料結構 |
| `assets/sprites/ASSET_MANIFEST.md` | 圖片資產清單（路徑、尺寸、狀態） |
| `production/session-logs/session-log.md` | Session 歷史紀錄 |

---

## Architecture Overview

### Magnet State Machine (Core Loop)
```
IDLE/AIMING → SINKING → RETRIEVING → CHECK → IDLE (loop)
```

### Existing Prototype Structure
- `Main.tscn` — 主場景：UI + 海底物資容器
- `Boat.tscn` — 船：左右移動 + 磁鐵掛載
- `Magnet.tscn` — 磁鐵：狀態機 + 物理
- `Fish.tscn` / `MetalObject.tscn` — 海底物件

---

## Known Issues / Bugs

| ID | Description | Severity | Status |
|----|------------|----------|--------|
| — | Phase A 所有 Bug 已修復（CHECK 路徑、舊 Label、Overlay 輸入阻擋） | — | Resolved |

---

## Design Decisions Made

1. **引擎**: Godot 4.3 + GDScript（2D 手遊最適合）
2. **美術風格**: Pixel Art
3. **回合時長**: 4 分鐘（手機碎片時間）
4. **永久進度**: 混合制（花錢升級 + 條件解鎖）
5. **操控**: 點擊放磁鐵、滑動微調、長按回收

---

## Next Recommended Actions

1. **上傳圖片** — 對照 `assets/sprites/ASSET_MANIFEST.md` 上傳 7 張 sprite（船、磁鐵、4 種金屬、魚）
2. **Feature 層 GDD** — 剩餘 4 個系統：物件吸附、物資生成、鏡頭、回合管理器
3. **整合測試** — 驗證完整遊戲循環：下潛 → 商店 → 回合結束 → 重試
4. **觸控操作適配** — 確認手機上的操作體驗
