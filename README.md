
# Grab2 — 磁鐵深海撈寶

一款 2D 物理抓取 Roguelite 手機遊戲。

## Game Overview

操控磁鐵沉入深海，在 4 分鐘一局的限時內撈取金屬物資和稀有遺物。透過 Roguelite 升級系統，每一次下潛都是全新的策略抉擇。

## Tech Stack

- **Engine**: Godot 4.3
- **Language**: GDScript
- **Art Style**: Pixel Art
- **Target Platform**: Mobile (iOS / Android)

## Project Structure

```
├── CLAUDE.md                    # AI agent 主設定
├── HANDOFF.md                   # 跨 Session 接手文件
├── design/gdd/                  # 遊戲設計文件
│   └── game-concept.md          # 遊戲概念
├── docs/engine-reference/       # 引擎版本參考
├── production/                  # 製程管理
│   ├── session-state/           # 當前 Session 狀態
│   └── session-logs/            # Session 歷史紀錄
├── Main.tscn / Main.gd          # 主場景
├── Boat.tscn / Boat.gd          # 船（玩家控制）
├── Magnet.tscn / Magnet.gd      # 磁鐵（核心機制）
├── Fish.tscn / Fish.gd          # 魚（海底物件）
└── MetalObject.tscn             # 金屬物件（可撈取）
```

## How to Run

1. 用 Godot 4.3 開啟 `project.godot`
2. 按 F5 執行主場景
3. A/D 移動船，點擊放磁鐵，長按回收

## Development Status

**Phase**: Pre-Production（概念確立，準備進入系統設計）

詳見 `HANDOFF.md` 了解當前進度。

# grab2
2b923cc040c3dd1d185b9c10de18ace63132d0d3
