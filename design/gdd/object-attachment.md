# 物件吸附系統 (Object Attachment)

> **Status**: In Design
> **Author**: user + agents
> **Last Updated**: 2026-03-25
> **Implements Pillar**: 一次下潛的滿足感

## Overview

物件吸附系統管理磁鐵與海底物件之間的物理連接關係。在磁鐵 SINKING 和 RETRIEVING 狀態下，Area2D 持續偵測範圍內的可吸附物件。當接觸發生時，系統建立物理連接（reparent 或 PinJoint2D），更新吸附列表，並即時計算總重量以回傳給磁鐵狀態機調整回收速度。此系統是「抓取手感」的核心執行者，直接決定玩家看到磁鐵吸住東西那一瞬間的回饋品質。

## Player Fantasy

「磁鐵掠過海底時突然咔嚓一聲吸住了一個東西 — 我感受到了它的重量，磁鐵上晃動的物件讓我知道這次收穫豐碩。一次吸住五個的那種滿載感，讓我迫不及待要看看都是什麼。」

目標 MDA 美學：**Sensation（感官滿足）**— 吸附的即時回饋、物件連在磁鐵上的視覺晃動、音效層次。**Challenge（挑戰）**— max_attach_count 限制創造的選擇壓力：要那個高重量遺物還是多抓兩個普通金屬？

## Detailed Design

### Core Rules

#### 1. 吸附觸發條件

- 磁鐵必須處於 `SINKING` 或 `RETRIEVING` 狀態（Area2D 開啟）
- 物件必須符合可吸附條件：`item.category` 為 METAL、RELIC、JUNK、CHEST 之一
- 當前吸附數量 `attached_count < max_attach_count`
- 物件尚未被吸附（`item.is_attached == false`）

若以上任一條件不符，吸附不發生。若數量已滿則發出 `attachment_full` 信號。

#### 2. 吸附方式

吸附採用 **reparent 方案**（預設）：

```
物件節點從其原本的父節點（WorldContainer）
reparent 到磁鐵的 AttachmentAnchor 子節點
物件的 RigidBody2D 切換為 freeze_mode = KINEMATIC
物件跟隨磁鐵移動，但保留相對偏移以呈現自然晃動
```

備選方案為 PinJoint2D，若原型測試發現 reparent 在多物件時不穩定則切換（見 Open Questions）。

#### 3. 吸附位置排列

物件依吸附順序排列於磁鐵下方，使用 **扇形螺旋排列**：

```
slot_offset(index) = Vector2(
    cos(index * attachment_angle_step) * attachment_radius,
    sin(index * attachment_angle_step) * attachment_radius * 0.5
)
```

- `attachment_angle_step` = 60 度（6 個槽位均分 360 度）
- `attachment_radius` = 30 px（距磁鐵中心）
- 最大 5 個物件均勻環繞磁鐵掛點

#### 4. 同幀多物件碰撞

同一幀若多個物件同時進入 Area2D：
1. 全部蒐集到 `collision_candidates` 列表
2. 按物件到磁鐵中心的距離由近到遠排序
3. 依序吸附，直到 `attached_count == max_attach_count`
4. 剩餘物件忽略

#### 5. 吸附後物件行為

- 物件 `freeze_mode = KINEMATIC`，不再受重力或碰撞影響
- 物件的碰撞 Shape 停用（不再與環境碰撞）
- 物件保留視覺晃動效果（輕微旋轉動畫，幅度 ±5 度，週期 0.8s）
- 物件的 HitBox 關閉，避免影響其他物件偵測

#### 6. 滿載處理

當 `attached_count == max_attach_count`：
- Area2D 偵測繼續運行（不關閉，因為回收途中可能解除限制）
- 新碰撞物件直接忽略
- 發出 `attachment_full` 信號，供 HUD 顯示視覺提示（磁鐵閃爍紅邊）

#### 7. 吸附列表清除

CHECK 狀態結束（所有物件處理完畢）後：
- 所有 attached_items 從磁鐵 reparent 回 WorldContainer 或直接移除場景
- `attached_count` 歸零
- `total_weight` 歸零

### States and Transitions

物件吸附系統本身無獨立狀態機，其行為由磁鐵狀態機驅動：

| 磁鐵狀態 | Area2D | 可吸附 | 說明 |
|---------|--------|--------|------|
| IDLE | 關閉 | 否 | 磁鐵在水面，不做偵測 |
| SINKING | 開啟 | 是 | 主要吸附視窗 |
| RETRIEVING | 開啟 | 是 | 回收途中可吸附途經物件（Bonus Catch） |
| CHECK | 關閉 | 否 | 正在結算，不允許新吸附 |

### Interactions with Other Systems

| 系統 | 方向 | 數據流 |
|------|------|--------|
| **磁鐵狀態機** | → 讀取 | 監聽 `state_changed` 信號以開關 Area2D；監聽 `item_contacted` 觸發吸附 |
| **物資資料庫** | → 讀取 | 讀取物件的 `weight`、`category`、`is_magnetic` 屬性 |
| **經濟系統** | ← 輸出 | CHECK 時傳遞 `attached_items: Array[ItemData]` 給經濟系統結算 |
| **磁鐵狀態機** | ← 輸出 | 提供 `total_weight` 供 retrieve_speed 公式使用 |
| **HUD 系統** | ← 輸出 | 提供 `attached_count`、`max_attach_count`、吸附物件列表 |
| **回合管理器** | ← 輸出 | 回合結算時提供 attached_items 清單 |

## Formulas

### 回收速度（引用 magnet-state-machine.md）

```
total_weight = sum(item.weight for item in attached_items)
retrieve_speed = base_retrieve_speed / (1 + total_weight * weight_drag_factor)
```

| Variable | Definition | Default | Range |
|----------|-----------|---------|-------|
| `base_retrieve_speed` | 無負重基礎回收速度 (px/s) | 300 | 200-500 |
| `total_weight` | 所有吸附物件 weight 之和 | — | 0.0 – 25.0 |
| `weight_drag_factor` | 重量對速度的影響係數 | 0.15 | 0.05-0.3 |

**範例計算**：
- 空載：speed = 300 / (1 + 0 × 0.15) = **300 px/s**
- 5 個 COMMON Metal (weight 0.5 each, total 2.5)：speed = 300 / (1 + 2.5 × 0.15) = 300 / 1.375 = **218 px/s**（-27%）
- 1 個 EPIC Metal (weight 4.0) + 1 個 Chest (weight 5.0)，total 9.0：speed = 300 / (1 + 9.0 × 0.15) = 300 / 2.35 = **128 px/s**（-57%）
- 最大負載 5 個 EPIC (weight 5.0 each, total 25.0)：speed = 300 / (1 + 25 × 0.15) = 300 / 4.75 = **63 px/s**，clamp 至最低 **50 px/s**

### 吸附位置偏移

```
slot_offset(index) = Vector2(
    cos(index * PI / 3.0) * attachment_radius,
    sin(index * PI / 3.0) * attachment_radius * 0.5
)
```

| Variable | Definition | Default | Range |
|----------|-----------|---------|-------|
| `attachment_radius` | 物件到磁鐵中心的距離 (px) | 30 | 20-50 |
| `PI / 3.0` | 每個槽位的角度間距 (60°) | 固定 | — |

## Edge Cases

| Edge Case | Resolution |
|-----------|-----------|
| `attached_count == max_attach_count` 時碰到新物件 | 忽略新物件，不呼叫任何吸附邏輯。發出 `attachment_full` 信號，HUD 顯示紅邊閃爍 1 秒 |
| 同幀碰到 10 個物件（超過上限 5 個） | 按距離排序，吸附最近的 5 個，其餘 5 個忽略 |
| `total_weight` 超過 25.0（理論最大值 5 × 5.0） | clamp total_weight = min(total_weight, 25.0) |
| 回收速度降至低於 50 px/s | clamp retrieve_speed = max(retrieve_speed, 50.0)，避免磁鐵卡在水中 |
| CHECK 期間物件仍在 AttachmentAnchor 子樹 | 不允許任何吸附操作，Area2D 已關閉 |
| 物件在被吸附的瞬間已被另一個場景實例刪除 | 在 area_entered 回呼中先做 `is_instance_valid(item)` 檢查，無效則跳過 |
| reparent 後物件視覺位置跳變 | reparent 時使用 `keep_global_transform = true` 再移動至 slot_offset |
| max_attach_count 因升級增加後超過 5 | 陣列和 UI 支援最多 8 個槽位（系統上限），允許升級擴增 |
| RETRIEVING 途中碰到物件且已滿載 | 與 SINKING 相同邏輯：忽略並發出 `attachment_full` 信號 |
| 兩個物件佔用同一個 slot_offset 位置（同時吸附） | 排隊處理，第二個物件取下一個可用 index |

## Dependencies

### Upstream（此系統依賴的系統）

- **磁鐵狀態機** (hard) — 提供 `state_changed` 和 `item_contacted` 信號作為吸附觸發器；回收速度公式的輸入來源在此系統，但速度應用在磁鐵狀態機
- **物資資料庫** (hard) — 讀取 `ItemData.weight`、`ItemData.category`、`ItemData.magnetic` 屬性

### Downstream（依賴此系統的系統）

- **磁鐵狀態機** (hard) — 需要 `total_weight` 計算 retrieve_speed
- **經濟系統** (hard) — CHECK 時需要 `attached_items: Array[ItemData]` 進行兌換
- **HUD 系統** (soft) — 需要 `attached_count`、`max_attach_count`、物件列表顯示
- **回合管理器** (soft) — 回合結算統計每次下潛的吸附數量

## Tuning Knobs

| Knob | Default | Safe Range | Affects | Too High | Too Low |
|------|---------|-----------|---------|----------|---------|
| `max_attach_count` | 5 | 3-8 | 每次下潛最多吸附物件數量 | 一次撈太多，CHECK 太快，回合縮短 | 每次下潛太少，策略空間狹窄 |
| `weight_drag_factor` | 0.15 | 0.05-0.3 | 重量對回收速度的影響強度 | 重物幾乎無法回收，玩家避免抓大物 | 重量無意義，失去策略選擇 |
| `retrieve_speed_floor` | 50 px/s | 30-100 | 最低回收速度下限 | 太高則滿載懲罰消失 | 太低則可能卡在水中，遊戲停滯 |
| `attachment_radius` | 30 px | 20-50 | 物件環繞磁鐵的視覺半徑 | 物件太散亂，碰撞混亂 | 物件堆疊，視覺難以辨識 |
| `area2d_radius` | 40 px | 25-60 | 磁鐵 Area2D 偵測範圍 | 遠距離自動吸附，失去準度 | 太難觸發吸附，挫折感 |
| `wobble_amplitude` | 5 度 | 2-15 | 吸附物件的晃動幅度 | 視覺過於混亂 | 物件看起來僵硬 |
| `wobble_period` | 0.8s | 0.5-2.0 | 吸附物件的晃動週期 | 晃動太慢不明顯 | 晃動太快，視覺疲勞 |

## Acceptance Criteria

1. **AC-01**: SINKING 和 RETRIEVING 狀態下，Area2D 進入物件時正確觸發吸附邏輯；IDLE 和 CHECK 狀態下 Area2D 不偵測
2. **AC-02**: 吸附後物件 reparent 到磁鐵 AttachmentAnchor，且 `keep_global_transform = true` 使視覺位置不跳變
3. **AC-03**: `attached_count` 達到 `max_attach_count` 時，後續碰撞的物件不被吸附，且 `attachment_full` 信號正確發出
4. **AC-04**: 同幀多物件碰撞按距離排序後依序吸附，不超過 max_attach_count
5. **AC-05**: `total_weight` 正確為所有 attached_items 的 weight 之和，且隨吸附/釋放即時更新
6. **AC-06**: retrieve_speed 依 `base_retrieve_speed / (1 + total_weight * weight_drag_factor)` 正確計算，且不低於 50 px/s
7. **AC-07**: 吸附物件顯示輕微晃動動畫（±5 度，0.8s 週期）
8. **AC-08**: CHECK 完成後 attached_items 清空，attached_count 歸零，scene 中的物件節點移除
9. **AC-09**: 最大負載（5 個 EPIC weight 5.0）時 retrieve_speed clamp 在 50 px/s 以上，磁鐵可回到水面
10. **AC-10（體驗標準）**: 遊玩測試中，8/10 位測試者能感受到吸附瞬間的「咔嚓」回饋（音效 + 視覺）

## Open Questions

1. **吸附方案選擇**: reparent vs PinJoint2D — reparent 較易控制但物理不真實；PinJoint2D 有真實晃動但多物件穩定性未驗證。建議原型同時測試兩方案，以手機幀率穩定性為判斷標準。
2. **RETRIEVING 途中的 Bonus Catch**: 回收時碰到物件是否也應吸附？目前設計為「是」，但可能降低「下潛精準感」。待原型測試。
3. **吸附優先順序**: 距離排序是否應改為「價值排序」（先吸附稀有度高的）？但玩家可能感覺「被系統操控」，失去自主性。暫定距離排序。
4. **吸附限制的視覺反饋**: 滿載時除了磁鐵紅邊閃爍外，是否需要數量文字提示？待 HUD 設計確認。
