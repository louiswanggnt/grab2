# Grab2 — Session Handoff

> **Last Updated**: 2026-03-26
> **Current Phase**: MVP Playable — 核心遊玩循環已可運行
> **Engine**: Godot 4.6.1 / GDScript

---

## Quick Context

**Grab2 是什麼？** 一款 2D 物理抓取 Roguelite 手機遊戲。玩家操控磁鐵沉入深海，在 4 分鐘內撈取金屬物資和稀有遺物，用收益升級裝備。

---

## Current State — MVP Playable ✅

### 可遊玩功能
- [x] 船左右移動（A/D 鍵）
- [x] 點擊放下磁鐵 → 重力下沉
- [x] 長按滑鼠 → 磁鐵向上拉；放開 → 繼續下沉
- [x] 下沉時船仍可移動（半速），磁鐵 X 軸同步
- [x] 碰到金屬物自動吸附（最大 3 件，可調）
- [x] 回到水面自動結算金錢
- [x] 右鍵丟棄最重物品
- [x] 125 個金屬物堆積在海床（4 種重量等級，大小∝重量）
- [x] 裝飾魚群在海中隨機游動
- [x] 雙鏡頭切換（船鏡頭 / 磁鐵鏡頭）
- [x] 回合計時器（240 秒）
- [x] **GameConfig 統一數值管理** — 所有可調參數集中在一個檔案

### GDD 文件（11/17 完成）
- [x] Foundation 層（3/3）：ItemDatabase、TouchInput、RoundTimer
- [x] Core 層（3/3）：BoatController、MagnetStateMachine、EconomySystem
- [x] Feature 層（4/5）：ObjectAttachment、ResourceSpawner、CameraSystem、RoundManager
- [x] Presentation 層（1/1）：HUD System
- [ ] Roguelite 層（0/3）：遺物系統、升級系統、解鎖系統
- [ ] Content 層（0/3）：海域系統、成就系統、存檔系統

---

## Architecture

### State Machine (簡化後)
```
IDLE → SINKING → CHECK → IDLE (loop)
        ↑ ↓
    長按上拉/放開下沉（同一狀態內切換）
```

### 核心檔案

| File | Purpose |
|------|---------|
| `autoload/game_config.gd` | **統一數值配置** — 所有可調參數的唯一來源 |
| `autoload/touch_input_manager.gd` | 輸入管理（鍵盤+滑鼠+觸控） |
| `src/magnet/magnet_state_machine.gd` | 磁鐵狀態機（IDLE/SINKING/CHECK） |
| `src/boat/boat_controller.gd` | 船控制器（水平移動） |
| `src/economy/economy_system.gd` | 經濟系統（金錢、賣出） |
| `src/main/round_timer.gd` | 回合計時器 |
| `src/items/item_data.gd` | ItemData Resource 定義 |
| `src/items/item_database.gd` | 物品資料庫 Autoload |
| `Main.gd` | 遊戲協調器（連接所有系統） |
| `Main.tscn` | 主場景 |
| `Boat.tscn` / `Magnet.tscn` | 船 / 磁鐵場景 |
| `MetalObject.tscn` | 金屬物（RigidBody2D + weight/value） |
| `Fish.tscn` | 裝飾魚（Node2D，無碰撞） |

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

---

## Design Decisions Made

1. **引擎**: Godot 4.6.1 + GDScript（2D 手遊最適合）
2. **美術風格**: Pixel Art（待替換 ColorRect 佔位符）
3. **回合時長**: 4 分鐘（手機碎片時間）
4. **操控**: 點擊放磁鐵、長按上拉/放開下沉、A/D 半速移動、右鍵丟棄
5. **狀態機簡化**: 移除 RETRIEVING 狀態，改用 `_is_pulling` 旗標在 SINKING 內切換
6. **統一配置**: 所有遊戲數值集中在 `autoload/game_config.gd`
7. **金屬物物理**: RigidBody2D 凍結在海床上，被吸附時 freeze → 跟隨磁鐵

---

## Next Recommended Actions

### 高優先（完善 MVP）
1. 升級商店 UI — 用金錢升級磁鐵吸附數量、回收速度、船速
2. HUD — 顯示金錢、計時器、吸附物品數
3. 回合結束畫面 — 顯示收益統計
4. 替換 ColorRect 為正式 Sprite 美術資源

### 中優先（Roguelite 層）
5. 遺物系統 — 稀有物品觸發三選一隨機升級
6. 多海域 — 不同深度、物資分佈、難度
7. 存檔系統 — 永久升級進度保存

### 低優先（Polish）
8. 音效 — 入水、吸附、結算音效
9. 視覺特效 — 水波、氣泡粒子
10. 觸控優化 — 手機觸控手勢完善
11. 成就系統
