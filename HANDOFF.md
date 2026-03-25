# Grab2 — Session Handoff

> **Last Updated**: 2026-03-25
> **Current Phase**: Pre-Production → Implementation Ready（6/11 MVP GDD 完成，資料夾結構已建立）

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

### In Progress
- [x] Core 層 GDD（3/3 完成）：
  - `design/gdd/boat-controller.md` — 船控制器
  - `design/gdd/magnet-state-machine.md` — 磁鐵狀態機
  - `design/gdd/economy-system.md` — 經濟系統
- [ ] Feature 層 GDD（0/4）：物件吸附、物資生成、鏡頭、回合管理器
- [ ] Presentation 層 GDD（0/1）：HUD
- [x] 程式碼資料夾結構 (`docs/architecture/folder-structure.md`)

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
| — | 尚無已知問題 | — | — |

---

## Design Decisions Made

1. **引擎**: Godot 4.3 + GDScript（2D 手遊最適合）
2. **美術風格**: Pixel Art
3. **回合時長**: 4 分鐘（手機碎片時間）
4. **永久進度**: 混合制（花錢升級 + 條件解鎖）
5. **操控**: 點擊放磁鐵、滑動微調、長按回收

---

## Next Recommended Actions

1. `/map-systems` — 分解遊戲系統、建立依賴圖
2. `/design-system <system-name>` — 逐系統撰寫 GDD
3. `/prototype magnet-grab` — 用現有代碼驗證核心循環
