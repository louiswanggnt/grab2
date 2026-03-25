# Grab2 — 程式碼資料夾結構

> **Created**: 2026-03-25
> **Status**: Approved

## 設計原則

1. **按功能分類**，不按節點類型 — `scenes/boat/` 而非 `scenes/` + `scripts/`
2. **場景和腳本放一起** — `boat.tscn` 和 `boat.gd` 在同一資料夾
3. **共用資源獨立** — data、autoload、ui 獨立資料夾
4. **平坦優於巢狀** — 避免超過 3 層深度

## 資料夾結構

```
res://
├── project.godot
├── icon.svg
│
├── src/                          # 所有遊戲原始碼和場景
│   ├── main/                     # 主場景和回合管理
│   │   ├── main.tscn             # 主場景（遊戲入口）
│   │   ├── main.gd               # 主場景腳本
│   │   └── round_manager.gd      # 回合管理器（開始/結束/結算）
│   │
│   ├── boat/                     # 船相關
│   │   ├── boat.tscn             # 船場景
│   │   └── boat.gd               # 船控制器
│   │
│   ├── magnet/                   # 磁鐵系統（核心）
│   │   ├── magnet.tscn           # 磁鐵場景
│   │   ├── magnet.gd             # 磁鐵狀態機
│   │   └── attachment.gd         # 物件吸附邏輯
│   │
│   ├── items/                    # 海底物件
│   │   ├── metal_object.tscn     # 金屬物件場景
│   │   ├── metal_object.gd       # 金屬物件行為
│   │   ├── chest.tscn            # 寶箱場景（Vertical Slice）
│   │   └── resource_spawner.gd   # 物資生成系統
│   │
│   ├── camera/                   # 鏡頭系統
│   │   └── game_camera.gd        # 鏡頭切換邏輯（船↔磁鐵）
│   │
│   └── ui/                       # UI 場景和腳本
│       ├── hud.tscn              # HUD（計時器、金錢、吸附數）
│       ├── hud.gd
│       ├── shop_ui.tscn          # 商店/升級介面（Vertical Slice）
│       ├── shop_ui.gd
│       ├── upgrade_popup.tscn    # Roguelite 三選一升級彈窗
│       └── upgrade_popup.gd
│
├── data/                         # 靜態數據（Resource 檔案）
│   ├── items/                    # ItemData 資源
│   │   ├── item_data.gd          # ItemData class_name 定義
│   │   ├── metals/               # 金屬物件資料
│   │   │   ├── iron_nail.tres
│   │   │   ├── copper_pipe.tres
│   │   │   ├── silver_ingot.tres
│   │   │   └── gold_nugget.tres
│   │   ├── junk/                 # 金屬垃圾資料
│   │   │   ├── empty_can.tres
│   │   │   └── rusty_scrap.tres
│   │   ├── relics/               # 遺物資料（Vertical Slice）
│   │   └── chests/               # 寶箱資料（Vertical Slice）
│   │
│   └── upgrades/                 # 升級定義
│       ├── upgrade_data.gd       # UpgradeData class_name 定義
│       ├── magnet_strength.tres
│       ├── retrieve_speed.tres
│       ├── boat_speed.tres
│       └── steering_power.tres
│
├── autoload/                     # 全域 Autoload 單例
│   ├── game_manager.gd           # 遊戲全域狀態（金錢、升級等級）
│   ├── economy.gd                # 經濟系統（兌換、購買邏輯）
│   ├── save_manager.gd           # 存檔系統（Vertical Slice）
│   └── input_manager.gd          # 觸控輸入抽象層
│
├── assets/                       # 美術和音效資源
│   ├── sprites/                  # 像素精靈圖
│   │   ├── boat/
│   │   ├── magnet/
│   │   ├── items/
│   │   ├── environment/          # 海底背景、水面
│   │   └── ui/                   # UI 圖標
│   ├── audio/                    # 音效和音樂
│   │   ├── sfx/
│   │   └── music/
│   └── fonts/                    # 字體
│
├── design/                       # 設計文件（不影響遊戲）
│   └── gdd/
│
├── docs/                         # 技術文件（不影響遊戲）
│   ├── architecture/
│   └── engine-reference/
│
└── production/                   # 製程文件（不影響遊戲）
```

## Autoload 配置

在 `project.godot` 中註冊：

| Autoload | Path | 用途 |
|----------|------|------|
| `GameManager` | `autoload/game_manager.gd` | 全域遊戲狀態：金錢、升級等級、當前回合數據 |
| `Economy` | `autoload/economy.gd` | 經濟邏輯：物資兌換、升級購買、定價計算 |
| `InputManager` | `autoload/input_manager.gd` | 輸入抽象：觸控/滑鼠統一映射，發出遊戲動作信號 |
| `SaveManager` | `autoload/save_manager.gd` | 存檔讀檔（Vertical Slice） |

## 檔案命名規範

| 類型 | 規範 | 範例 |
|------|------|------|
| 資料夾 | snake_case | `metal_object/` |
| GDScript | snake_case | `round_manager.gd` |
| Scene | snake_case | `metal_object.tscn` |
| Resource | snake_case | `iron_nail.tres` |
| class_name | PascalCase | `ItemData`, `UpgradeData` |
| Sprite | snake_case | `boat_idle.png` |

## 現有檔案遷移計劃

| 現在位置 | 移到 | 說明 |
|---------|------|------|
| `Main.gd` / `Main.tscn` | `src/main/main.gd` / `.tscn` | 重構為新架構 |
| `Boat.gd` / `Boat.tscn` | `src/boat/boat.gd` / `.tscn` | 重構船控制器 |
| `Magnet.gd` / `Magnet.tscn` | `src/magnet/magnet.gd` / `.tscn` | 重構為正式狀態機 |
| `Fish.gd` / `Fish.tscn` | 刪除或移到 `src/items/` | 原型中的魚，改為正式物件系統 |
| `MetalObject.tscn` | `src/items/metal_object.tscn` | 加入 ItemData 資源引用 |

> **注意**：遷移時原型代碼將被重寫，不是簡單搬移。GDD 中的設計規格才是實作依據。
