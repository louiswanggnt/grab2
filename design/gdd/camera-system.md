# 鏡頭系統 (Camera System)

> **Status**: In Design
> **Author**: user + agents
> **Last Updated**: 2026-03-25
> **Implements Pillar**: 一次下潛的滿足感 / 4 分鐘就是一個完整體驗

## Overview

鏡頭系統根據磁鐵狀態機的當前狀態，動態切換 Camera2D 的追蹤目標並管理場景視角。IDLE 和 CHECK 狀態時鏡頭追蹤船（水面視角），SINKING 和 RETRIEVING 狀態時追蹤磁鐵（水下視角）。切換使用平滑過渡（位置 lerp）而非瞬切，確保玩家空間感連貫。此系統針對手機直向螢幕（Portrait）最佳化，縱向視野帶來「深潛感」的視覺體驗。

## Player Fantasy

「釋放磁鐵的那一刻，鏡頭隨著磁鐵一起沉入黑暗的深海 — 越深越暗，越深越遠離安全的水面。回收時鏡頭帶我重新看見光線，感覺自己從深海歸來。」

目標 MDA 美學：**Sensation（感官體驗）**— 鏡頭運動本身就是敘事工具，傳達深潛的物理感受。**Fantasy（幻想）**— 視角跟隨磁鐵下沉強化「磁鐵即我的分身」的代入感。

## Detailed Design

### Core Rules

#### 1. 追蹤目標切換規則

| 磁鐵狀態 | Camera 追蹤目標 | 視角說明 |
|---------|----------------|---------|
| IDLE | 船（Boat）的 CameraAnchor 位置 | 水面視角，可見船和水面環境 |
| SINKING | 磁鐵（Magnet）的位置 | 隨磁鐵下沉，視野進入水下 |
| RETRIEVING | 磁鐵（Magnet）的位置 | 隨磁鐵上升，視野逐漸回到水面 |
| CHECK | 船（Boat）的 CameraAnchor 位置 | 回到水面，顯示結算 UI |

#### 2. 目標切換方式

目標切換使用 **平滑位置插值（lerp 追蹤）**，而非硬切換：

```gdscript
# 每幀更新
var target_position = current_target.global_position + camera_offset
camera.global_position = camera.global_position.lerp(target_position, follow_speed * delta)
```

切換到新目標時，插值繼續從當前 Camera 位置開始，無需重置。這確保在狀態轉換瞬間鏡頭運動連貫，不產生跳切。

#### 3. 跟隨速度（Follow Speed）

| 狀態 | follow_speed | 說明 |
|------|-------------|------|
| IDLE | 3.0 | 鬆散跟隨，船的橫向移動感覺輕快 |
| SINKING | 2.0 | 稍慢，給磁鐵下沉留一點鏡頭延遲以強化「重量感」 |
| RETRIEVING | 4.0 | 快速跟隨，確保回收時玩家能看到磁鐵和吸附物件 |
| CHECK（切換回船） | 2.5 | 平穩回到水面，不急促 |

#### 4. 鏡頭偏移（Camera Offset）

- IDLE / CHECK 時：Camera 偏移 `(0, -camera_surface_offset)` 向上，讓水面可見且船在畫面下方 1/3 處
- SINKING / RETRIEVING 時：無偏移（磁鐵在畫面中央）

```
camera_surface_offset = 80 px（向上偏移，讓玩家看到水面以上一點環境）
```

#### 5. Portrait 螢幕適配

遊戲針對手機直向螢幕（Portrait，9:19.5 約）：

- 螢幕寬度：380-430 px（邏輯座標，依裝置解析度縮放）
- 螢幕高度：820-950 px（邏輯座標）
- Camera 使用 `Zoom = Vector2(1.0, 1.0)` 為基準，不做縮放
- 垂直視野更大，強化「縱深感」，磁鐵下沉方向符合手持閱讀方向（自然向下）

#### 6. 鏡頭邊界限制（Camera Limits）

Camera2D 設定 `limit_*` 屬性防止超出場景邊界：

```
limit_left = 0
limit_right = scene_width (px)
limit_top = -200 px（允許看到少量天空/水面上方）
limit_bottom = max_depth + 100 px（深水區底部 + 緩衝）
```

- `scene_width` = 480 px（邏輯寬度，與物資生成系統對齊）
- `max_depth` = 2000 px（與磁鐵狀態機對齊）

#### 7. 深度視覺效果（與鏡頭同步，非獨立系統）

鏡頭系統同時驅動以下視覺參數，依磁鐵 Y 座標（深度）線性插值：

| 視覺效果 | 淺水（800 px） | 深水（2000 px） | 說明 |
|---------|----------------|----------------|------|
| 環境光亮度 | 1.0 | 0.3 | 越深越暗 |
| 水流粒子密度 | 低 | 高 | 深水更多泡泡/水流粒子 |
| 霧效 Alpha | 0.0 | 0.6 | 深水區輕微霧化效果 |

> 注意：視覺效果的實作由美術/技術美術負責，此系統只提供插值參數計算的設計規格。

### States and Transitions

| 觸發 | 舊目標 | 新目標 | 切換行為 |
|------|--------|--------|---------|
| IDLE → SINKING | 船 | 磁鐵 | lerp 開始從船位置移向磁鐵，follow_speed = 2.0 |
| SINKING → RETRIEVING | 磁鐵 | 磁鐵 | 目標不變，follow_speed 維持 2.0（或可改 4.0 讓玩家看清磁鐵） |
| RETRIEVING → CHECK | 磁鐵 | 船 | lerp 從磁鐵當前位置移回船，follow_speed = 2.5 |
| CHECK → IDLE | 船 | 船 | 目標不變，鏡頭已在船附近無需切換 |

### Interactions with Other Systems

| 系統 | 方向 | 數據流 |
|------|------|--------|
| **磁鐵狀態機** | → 讀取 | 監聽 `state_changed` 信號以切換追蹤目標；讀取磁鐵 `global_position` |
| **船控制器** | → 讀取 | 讀取船的 `global_position`（追蹤目標位置來源） |
| **物資生成系統** | → 讀取 | 讀取場景邊界設定 Camera2D limit 值 |
| **HUD 系統** | ← 輸出 | 提供深度數值（`current_depth = magnet.position.y`）供 HUD 顯示（如有需要） |

## Formulas

### 深度插值參數計算

```
depth_t = clamp((magnet_y - shallow_y) / (deep_y - shallow_y), 0.0, 1.0)
```

| Variable | Definition | Default |
|----------|-----------|---------|
| `magnet_y` | 磁鐵當前 Y 座標 (px) | 動態值 |
| `shallow_y` | 淺水區起始 Y | 800 |
| `deep_y` | 深水區終止 Y | 2000 |
| `depth_t` | 深度插值係數（0=淺水,1=深水） | 0.0-1.0 |

深度相關的視覺效果計算：

```
ambient_brightness = lerp(1.0, 0.3, depth_t)
fog_alpha = lerp(0.0, 0.6, depth_t)
```

### 鏡頭跟隨位置

```
target_pos = tracked_node.global_position + camera_offset
camera.global_position = camera.global_position.lerp(target_pos, follow_speed * delta)
```

**範例計算**（delta = 0.016s，follow_speed = 2.0，current = (240, 800)，target = (240, 900)）：
- lerp_factor = 2.0 × 0.016 = 0.032
- new_y = 800 + (900 - 800) × 0.032 = **803.2 px**（每幀逼近 3.2 px，約 31 幀到達，約 0.5 秒追上）

### 鏡頭到達目標的時間估算

對於 lerp 追蹤，「到達 95% 距離」的估算時間：

```
frames_to_95pct = ln(0.05) / ln(1 - follow_speed * delta)
```

| follow_speed | 距離（px） | 95% 到達時間（60fps） |
|-------------|----------|---------------------|
| 2.0 | 100 | ~1.5s |
| 3.0 | 100 | ~1.0s |
| 4.0 | 100 | ~0.75s |

> 設計意圖：SINKING 時 follow_speed=2.0 讓鏡頭「慢一拍」跟上磁鐵，強化下沉的物理重量感。

## Edge Cases

| Edge Case | Resolution |
|-----------|-----------|
| 磁鐵在 SINKING/RETRIEVING 期間高速移動，鏡頭追不上 | lerp 追蹤自然處理：持續逼近。不強制瞬切，延遲感是設計預期 |
| 磁鐵到達 limit_bottom（2100 px）繼續移動（理論不應發生） | Camera limit 自動夾住，磁鐵可超出但 Camera 不超出；磁鐵狀態機的 max_depth 應先觸發強制回收 |
| 船移動到場景左/右邊界時 Camera 被 limit 夾住，追蹤延遲看起來奇怪 | 在邊界時直接 clamp Camera 位置，不用 lerp（加入 `near_boundary` 檢查） |
| CHECK 完成後立即再次下潛，鏡頭還未回到船位置就切換回追蹤磁鐵 | 鏡頭平滑從當前位置（可能仍在水下）直接開始追蹤新的磁鐵目標，lerp 自然處理 |
| 遊戲在 SINKING 中暫停，恢復後鏡頭位置跳變 | 暫停期間停止 lerp 更新（在 `_physics_process` 中判斷 `get_tree().paused`） |
| 裝置螢幕比例非預設（平板等） | Camera 保持中心點不變，超出部分顯示背景（設計為延伸水下背景，非黑邊） |

## Dependencies

### Upstream（此系統依賴的系統）

- **磁鐵狀態機** (hard) — 提供 `state_changed` 信號和磁鐵 `global_position`
- **船控制器** (hard) — 提供船的 `global_position` 作為 IDLE/CHECK 追蹤目標
- **物資生成系統** (soft) — 提供場景邊界數值以設定 Camera2D limits

### Downstream（依賴此系統的系統）

- **HUD 系統** (soft) — 可選讀取當前深度值顯示深度計

## Tuning Knobs

| Knob | Default | Safe Range | Affects | Too High | Too Low |
|------|---------|-----------|---------|----------|---------|
| `follow_speed_idle` | 3.0 | 1.5-6.0 | IDLE 時船的追蹤速度 | 鏡頭如膠水黏著，失去慣性感 | 鏡頭太慢，船已停止但鏡頭還在移動 |
| `follow_speed_sinking` | 2.0 | 1.0-4.0 | 下沉時磁鐵的追蹤速度 | 失去「重量感」（鏡頭太敏捷） | 磁鐵跑到畫面外，玩家看不到 |
| `follow_speed_retrieving` | 4.0 | 2.0-8.0 | 回收時的追蹤速度 | 畫面晃動感強 | 回收時磁鐵離開畫面 |
| `follow_speed_check` | 2.5 | 1.5-5.0 | 切換回船的速度 | 回到水面太急促 | 切換太慢，CHECK UI 顯示時鏡頭還在水下 |
| `camera_surface_offset` | 80 px | 40-150 | IDLE/CHECK 時鏡頭向上偏移 | 船在畫面底部太擠 | 看不到水面以上環境 |
| `depth_fog_max_alpha` | 0.6 | 0.3-0.9 | 深水區最大霧效濃度 | 深水區視覺不清，遊戲性受影響 | 深水無沉浸感 |
| `depth_ambient_min` | 0.3 | 0.1-0.6 | 深水區最暗亮度 | 深水區完全看不到物件 | 深水區看起來和淺水一樣明亮 |

## Acceptance Criteria

1. **AC-01**: 磁鐵 SINKING 後 Camera 追蹤目標從船切換到磁鐵，無瞬切，使用 lerp 平滑過渡
2. **AC-02**: 磁鐵 RETRIEVING 到水面觸發 CHECK 後，Camera 平滑切換回船位置，時間不超過 2 秒（follow_speed=2.5 × 1.5 秒估算）
3. **AC-03**: Camera 不超出 `limit_left/right/top/bottom` 定義的邊界
4. **AC-04**: 深度插值係數（depth_t）正確：磁鐵在 Y=800 時 depth_t=0.0，Y=2000 時 depth_t=1.0
5. **AC-05**: 環境亮度在 Y=800 時為 1.0，Y=2000 時為 0.3，中間值線性插值（誤差 ±0.05）
6. **AC-06**: 在 iPhone 14（390×844 pt）和 Android 標準（360×780 pt）上，鏡頭範圍不顯示黑邊
7. **AC-07（體驗標準）**: 遊玩測試中，鏡頭切換不令 8/10 位測試者感到暈眩或困惑

## Open Questions

1. **SINKING 時是否鎖定 X 軸**: 目前設計是 X/Y 都跟隨磁鐵，但若磁鐵橫向移動幅度太大，鏡頭水平晃動可能產生不適感。考慮 X 軸使用更低的 follow_speed（1.0），或只追蹤 Y 軸讓 X 軸緩動。
2. **水面視覺分界線**: 是否在 Camera 過渡時顯示明確的「入水/出水」動畫效果（水幕/折射）？待美術確認。
3. **深度數值顯示**: HUD 是否需要顯示當前深度（如「深度：1340m」）？若要顯示，Camera System 需提供 depth_t 或直接深度值。
