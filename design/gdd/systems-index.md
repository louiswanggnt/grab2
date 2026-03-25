# Systems Index: Grab2 — 磁鐵深海撈寶

> **Status**: Draft
> **Created**: 2026-03-25
> **Last Updated**: 2026-03-25
> **Source Concept**: design/gdd/game-concept.md

---

## Overview

Grab2 是一款以「磁鐵抓取」為核心的 2D Roguelite 手機遊戲。系統架構圍繞三個層面展開：
1. **核心操作層** — 磁鐵狀態機驅動的抓取循環（30 秒級）
2. **回合策略層** — 物資兌換和 Roguelite 升級構成的 4 分鐘回合弧線
3. **跨局成長層** — 永久升級和解鎖帶來的長期動力

Pillar 對齊：每個系統必須服務於「一次下潛的滿足感」、「4 分鐘完整體驗」或「每局都不一樣」至少一個支柱。

---

## Systems Enumeration

| # | System Name | Category | Priority | Status | Design Doc | Depends On |
|---|------------|----------|----------|--------|------------|------------|
| 1 | 物資資料庫 (Item Database) | Economy | MVP | Designed | design/gdd/item-database.md | — |
| 2 | 觸控輸入系統 (Touch Input) | Core | MVP | Designed | design/gdd/touch-input.md | — |
| 3 | 回合計時系統 (Round Timer) | Core | MVP | Designed | design/gdd/round-timer.md | — |
| 4 | 船控制器 (Boat Controller) | Core | MVP | Not Started | — | 觸控輸入 |
| 5 | 磁鐵狀態機 (Magnet State Machine) | Gameplay | MVP | Not Started | — | 觸控輸入, 物資資料庫 |
| 6 | 物件吸附系統 (Object Attachment) | Gameplay | MVP | Not Started | — | 磁鐵狀態機 |
| 7 | 經濟系統 (Economy) | Economy | MVP | Not Started | — | 物資資料庫 |
| 8 | 物資生成系統 (Resource Spawner) | Gameplay | MVP | Not Started | — | 物資資料庫 |
| 9 | 鏡頭系統 (Camera System) | Core | MVP | Not Started | — | 船控制器, 磁鐵狀態機 |
| 10 | 回合管理器 (Round Manager) | Gameplay | MVP | Not Started | — | 回合計時, 磁鐵狀態機, 經濟系統 |
| 11 | HUD 系統 (HUD) | UI | MVP | Not Started | — | 回合計時, 經濟系統, 物件吸附 |
| 12 | 遺物掉落表 (Relic Loot Table) | Economy | Vertical Slice | Not Started | — | — |
| 13 | Roguelite 升級系統 (Roguelite Upgrades) | Progression | Vertical Slice | Not Started | — | 遺物掉落表, 經濟系統 |
| 14 | 永久進度系統 (Permanent Progression) | Progression | Vertical Slice | Not Started | — | 經濟系統, 存檔系統 |
| 15 | 存檔系統 (Save/Load) | Persistence | Vertical Slice | Not Started | — | — |
| 16 | 商店/升級 UI (Shop UI) | UI | Vertical Slice | Not Started | — | 永久進度, 經濟系統 |
| 17 | 教學/引導系統 (Tutorial) | Meta | Alpha | Not Started | — | 回合管理器, HUD |

---

## Categories

| Category | Description |
|----------|-------------|
| **Core** | 基礎系統：輸入、鏡頭、計時 |
| **Gameplay** | 遊戲性系統：磁鐵操控、物資、吸附 |
| **Economy** | 資源系統：物品定義、金錢、掉落表 |
| **Progression** | 成長系統：Roguelite 升級、永久進度 |
| **Persistence** | 持久化：存檔/讀檔 |
| **UI** | 介面：HUD、商店 |
| **Meta** | 輔助系統：教學 |

---

## Priority Tiers

| Tier | Definition | Systems Count |
|------|------------|---------------|
| **MVP** | 核心循環可運行：一局完整的抓取遊戲 | 11 |
| **Vertical Slice** | 完整體驗：Roguelite 層 + 跨局進度 | 5 |
| **Alpha** | 新手引導和輔助系統 | 1 |

---

## Dependency Map

### Foundation Layer (no dependencies)

1. **物資資料庫** — 所有物件的數據定義（類型、價值、稀有度、重量）
2. **觸控輸入系統** — 輸入抽象層（點擊、滑動、長按的統一介面）
3. **回合計時系統** — 獨立計時器，無外部依賴
4. **遺物掉落表** — 遺物種類和機率定義（Vertical Slice）
5. **存檔系統** — 持久化基礎（Vertical Slice）

### Core Layer (depends on Foundation)

1. **船控制器** — depends on: 觸控輸入
2. **磁鐵狀態機** — depends on: 觸控輸入, 物資資料庫
3. **經濟系統** — depends on: 物資資料庫

### Feature Layer (depends on Core)

1. **物件吸附系統** — depends on: 磁鐵狀態機
2. **物資生成系統** — depends on: 物資資料庫
3. **鏡頭系統** — depends on: 船控制器, 磁鐵狀態機
4. **回合管理器** — depends on: 回合計時, 磁鐵狀態機, 經濟系統
5. **Roguelite 升級系統** — depends on: 遺物掉落表, 經濟系統（Vertical Slice）
6. **永久進度系統** — depends on: 經濟系統, 存檔系統（Vertical Slice）

### Presentation Layer (depends on Features)

1. **HUD 系統** — depends on: 回合計時, 經濟系統, 物件吸附
2. **商店/升級 UI** — depends on: 永久進度, 經濟系統（Vertical Slice）
3. **教學/引導系統** — depends on: 回合管理器, HUD（Alpha）

---

## Circular Dependencies

- None found — 依賴圖為乾淨的 DAG

---

## Recommended Design Order

| Order | System | Priority | Layer | Est. Effort |
|-------|--------|----------|-------|-------------|
| 1 | 物資資料庫 (Item Database) | MVP | Foundation | S |
| 2 | 觸控輸入系統 (Touch Input) | MVP | Foundation | S |
| 3 | 回合計時系統 (Round Timer) | MVP | Foundation | S |
| 4 | 船控制器 (Boat Controller) | MVP | Core | S |
| 5 | 磁鐵狀態機 (Magnet State Machine) | MVP | Core | L |
| 6 | 經濟系統 (Economy) | MVP | Core | M |
| 7 | 物件吸附系統 (Object Attachment) | MVP | Feature | M |
| 8 | 物資生成系統 (Resource Spawner) | MVP | Feature | S |
| 9 | 鏡頭系統 (Camera System) | MVP | Feature | S |
| 10 | 回合管理器 (Round Manager) | MVP | Feature | M |
| 11 | HUD 系統 (HUD) | MVP | Presentation | S |
| 12 | 遺物掉落表 (Relic Loot Table) | VS | Foundation | M |
| 13 | 存檔系統 (Save/Load) | VS | Foundation | S |
| 14 | Roguelite 升級系統 (Roguelite Upgrades) | VS | Feature | L |
| 15 | 永久進度系統 (Permanent Progression) | VS | Feature | M |
| 16 | 商店/升級 UI (Shop UI) | VS | Presentation | S |
| 17 | 教學/引導系統 (Tutorial) | Alpha | Presentation | M |

---

## High-Risk Systems

| System | Risk Type | Risk Description | Mitigation |
|--------|-----------|-----------------|------------|
| 磁鐵狀態機 | Technical + Design | 物理模擬手感需反覆調校，SINKING 觸控操作精度未驗證 | 最早原型測試 |
| 物件吸附系統 | Technical | PinJoint2D 多物件穩定性、手機效能 | 原型驗證不同方案 |
| Roguelite 升級系統 | Design | 4 分鐘內升級影響感可能不足，平衡調校耗時 | 紙面模擬 + 原型 |
| 經濟系統 | Design | 永久升級數值曲線需避免「升滿無動力」 | 數學建模 + 測試 |

---

## Progress Tracker

| Metric | Count |
|--------|-------|
| Total systems identified | 17 |
| Design docs started | 3 |
| Design docs reviewed | 0 |
| Design docs approved | 0 |
| MVP systems designed | 3/11 |
| Vertical Slice systems designed | 0/5 |

---

## Next Steps

- [ ] Design MVP Foundation systems first (`/design-system item-database`)
- [ ] Design 磁鐵狀態機 as highest-risk MVP system
- [ ] Run `/design-review` on each completed GDD
- [ ] Prototype 磁鐵狀態機 + 物件吸附 early (`/prototype magnet-grab`)
- [ ] Run `/gate-check pre-production` when MVP systems are designed
