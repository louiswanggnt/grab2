
# Grab2 — 磁鐵深海撈寶

一款 2D 物理抓取 Roguelite 手機遊戲。

## Game Overview

操控磁鐵沉入深海，在 4 分鐘一局的限時內撈取金屬物資和稀有遺物。透過 Roguelite 升級系統，每一次下潛都是全新的策略抉擇。

## Tech Stack

- **Engine**: Godot 4.6.1
- **Language**: GDScript
- **Art Style**: Pixel Art（目前為 ColorRect 佔位符）
- **Target Platform**: Mobile (iOS / Android)

## How to Run

1. 用 Godot 4.6+ 開啟 `project.godot`
2. 按 F5 執行主場景
3. **A/D** 移動船，**點擊**放磁鐵，**長按**上拉/**放開**下沉，**右鍵**丟棄最重物品

## Project Structure

```
├── autoload/                    # Autoload 單例
│   ├── game_config.gd           # 統一數值配置（所有可調參數）
│   └── touch_input_manager.gd   # 輸入管理
├── src/                         # 遊戲邏輯
│   ├── boat/boat_controller.gd  # 船控制器
│   ├── magnet/magnet_state_machine.gd # 磁鐵狀態機
│   ├── economy/economy_system.gd # 經濟系統
│   ├── items/                   # 物品資料
│   └── main/round_timer.gd     # 回合計時器
├── design/gdd/                  # 遊戲設計文件（11/17 完成）
├── Main.tscn / Main.gd          # 主場景 + 協調器
├── Boat.tscn / Magnet.tscn      # 船 / 磁鐵場景
├── MetalObject.tscn             # 金屬物件（RigidBody2D）
├── Fish.tscn                    # 裝飾魚（Node2D）
├── HANDOFF.md                   # 跨 Session 接手文件
└── production/session-logs/     # Session 歷史紀錄
```

## Development Status

**Phase**: MVP Playable ✅

核心遊玩循環已可運行。詳見 `HANDOFF.md` 了解當前進度和待辦事項。
