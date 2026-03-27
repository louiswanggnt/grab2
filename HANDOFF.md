# Grab2 — Session Handoff

> **Last Updated**: 2026-03-27
> **Current Phase**: MVP Complete — 準備進入 Roguelite 層
> **Engine**: Godot 4.6.1 / GDScript

---

## Quick Context

**Grab2 是什麼？** 一款 2D 物理抓取 Roguelite 手機遊戲。玩家操控磁鐵沉入深海，在 4 分鐘內撈取金屬物資和稀有遺物，用收益升級裝備。

---

## Current State — MVP Complete ✅

### 可遊玩功能
- [x] 船左右移動（A/D 鍵）
- [x] 點擊放下磁鐵 → 重力下沉
- [x] 長按滑鼠 → 磁鐵向上拉；放開 → 繼續下沉
- [x] 下沉時船仍可移動（半速），磁鐵 X 軸同步
- [x] 碰到金屬物自動吸附（最大 3 件，可調）
- [x] 右鍵丟棄最重物品
- [x] 125 個金屬物堆積在海床（4 種重量等級 × 3 變體，大小可控）
- [x] 裝飾魚群在海中隨機游動
- [x] 雙鏡頭切換（船鏡頭 / 磁鐵鏡頭）
- [x] 回合計時器（240 秒）
- [x] **GameConfig 統一數值管理** — 所有可調參數集中在一個檔案

### 停止條件（磁鐵）
- [x] 最大深度 → 位置鉗制 + 速度歸零
- [x] 碰觸海底 → 位置鉗制 + 速度歸零（位置檢測，非碰撞）
- [x] 滿載碰金屬 → 位置鉗制 + 速度歸零
- [x] 所有上拉由玩家長按控制，不自動回收

### UI 系統
- [x] **HUD** — 金錢、計時器、吸附物品數即時顯示
- [x] **商店** — 🛒 icon 始終可見，純手動點擊開啟，升級磁力/回收速度/船速/操控
- [x] **回合結束畫面** — 時間到顯示收益統計 + 重試按鈕
- [x] **收藏庫** — 📦 icon 始終可見，顯示所有物品收集進度，未發現物品隱藏
- [x] **物資清點動畫** — 磁鐵回到船上後，物品一個一個往上飄+淡出，金錢逐筆增加

### 美術
- [x] 美術替換管線就緒（`ResourceLoader.exists()` + fallback ColorRect）
- [x] `ASSET_MANIFEST.md` 定義所有圖片路徑
- [x] 已導入：boat.png, metal_light.png, metal_heavy.png, fish.png

### 狀態機（簡化後）
```
IDLE → SINKING → IDLE (loop)
       ↑ ↓
   長按上拉/放開下沉（同一狀態內切換）
```
- CHECK 狀態已移除出正常流程（SINKING 直接回 IDLE）
- 商店完全獨立於磁鐵狀態，純手動觸發

### GDD 文件（11/17 完成）
- [x] Foundation 層（3/3）：ItemDatabase、TouchInput、RoundTimer
- [x] Core 層（3/3）：BoatController、MagnetStateMachine、EconomySystem
- [x] Feature 層（4/5）：ObjectAttachment、ResourceSpawner、CameraSystem、RoundManager
- [x] Presentation 層（1/1）：HUD System
- [ ] Roguelite 層（0/3）：遺物系統、升級系統、解鎖系統
- [ ] Content 層（0/3）：海域系統、成就系統、存檔系統

---

## Architecture

### 核心檔案

| File | Purpose |
|------|---------|
| `autoload/game_config.gd` | **統一數值配置** — 所有可調參數、金屬物定義（含多變體） |
| `autoload/touch_input_manager.gd` | 輸入管理（鍵盤+滑鼠+觸控） |
| `src/magnet/magnet_state_machine.gd` | 磁鐵狀態機（IDLE/SINKING），停止條件（海底/滿載/最大深度） |
| `src/boat/boat_controller.gd` | 船控制器（水平移動，始終可移動） |
| `src/economy/economy_system.gd` | 經濟系統（金錢、升級） |
| `src/main/round_timer.gd` | 回合計時器 |
| `src/main/round_stats.gd` | 回合統計追蹤 |
| `src/collection/collection_tracker.gd` | 收藏追蹤（跨回合保留） |
| `src/items/metal_object.gd` | 金屬物（多變體、sprite 載入） |
| `src/ui/hud.gd` | HUD 顯示 |
| `src/ui/shop_panel.gd` | 商店面板（手動觸發） |
| `src/ui/round_end_screen.gd` | 回合結束畫面 |
| `src/ui/collection_panel.gd` | 收藏庫面板 |
| `Main.gd` | 遊戲協調器（連接所有系統 + 清點動畫） |
| `Main.tscn` | 主場景（SeaGradient 5 層海水 + Seabed） |

### 設計文件

| File | Purpose |
|------|---------|
| `design/gdd/game-concept.md` | 遊戲概念文件 |
| `design/gdd/systems-index.md` | 系統索引（17 系統、依賴圖） |
| `design/gdd/*.md` | 各系統 GDD（11 個已完成） |

---

## Known Issues / Limitations

| ID | Description | Severity | Status |
|----|------------|----------|--------|
| 1 | Magnet.gd / Boat.gd 舊原型腳本仍存在但未使用 | Low | Open |
| 2 | economy_system.gd 的 `relic_found` signal 已宣告但未使用 | Low | Open |
| 3 | ItemDatabase autoload 載入 0 items（generate_items.gd 需先執行生成 .tres） | Medium | Open |
| 4 | TouchInputManager 觸控裝置上 `_check_tap_distance` 使用 `get_mouse_position` | Medium | Open |
| 5 | hud.gd 使用 magic numbers (0, 1) 代替 State enum | Low | Open |

---

## Design Decisions Made

1. **引擎**: Godot 4.6.1 + GDScript（2D 手遊最適合）
2. **美術風格**: Pixel Art（`ResourceLoader.exists()` + fallback 模式）
3. **回合時長**: 4 分鐘（手機碎片時間）
4. **操控**: 點擊放磁鐵、長按上拉/放開下沉、A/D 半速移動、右鍵丟棄
5. **狀態機簡化**: 只有 IDLE/SINKING 正常流程，CHECK 已停用
6. **統一配置**: 所有遊戲數值集中在 `autoload/game_config.gd`
7. **金屬物物理**: RigidBody2D 凍結在海床上，被吸附時 freeze → 跟隨磁鐵
8. **商店獨立**: 商店完全手動觸發，不綁定磁鐵狀態，不鎖定船移動
9. **清點動畫**: 物品脫離磁鐵後獨立動畫（避免 RigidBody2D 推動 CharacterBody2D）
10. **多變體系統**: 每種金屬有多個變體（不同外觀/價值），spawner 隨機挑選
11. **收藏系統**: 跨回合持久，未發現物品隱藏資訊

---

## Next Phase — Roguelite 層

### 高優先（Roguelite 核心循環）
1. **遺物系統** — 稀有物品觸發三選一隨機被動升級
2. **永久升級** — 跨回合累積的永久強化（回合間商店 vs 永久解鎖）
3. **多海域** — 不同深度、物資分佈、難度曲線

### 中優先
4. **存檔系統** — 永久升級進度保存
5. **解鎖系統** — 新船、新磁鐵、新海域的解鎖條件

### 低優先（Polish）
6. 音效 — 入水、吸附、結算音效
7. 視覺特效 — 水波、氣泡粒子
8. 觸控優化 — 手機觸控手勢完善
9. 成就系統
