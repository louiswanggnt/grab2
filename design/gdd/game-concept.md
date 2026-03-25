# Game Concept: Grab2 — 磁鐵深海撈寶

*Created: 2026-03-25*
*Status: Draft*

---

## Elevator Pitch

> 一款 2D 物理抓取 Roguelite 手機遊戲。你操控磁鐵沉入深海，在 4 分鐘內盡可能撈取金屬物資和稀有遺物，用收益升級裝備、解鎖新海域，每一次下潛都是全新的策略抉擇。

---

## Core Identity

| Aspect | Detail |
| ---- | ---- |
| **Genre** | 2D 側捲軸 / 物理抓取 / Roguelite |
| **Platform** | Mobile (iOS / Android)，次要 PC |
| **Target Audience** | 手機休閒玩家，喜歡碎片時間遊戲 |
| **Player Count** | Single-player |
| **Session Length** | 4 分鐘一局，典型 session 2-3 局（10-15 分鐘） |
| **Monetization** | 待定（Premium 或 F2P + 廣告移除） |
| **Estimated Scope** | Small-Medium（2-4 個月） |
| **Comparable Titles** | 黃金礦工 (Gold Miner)、Vampire Survivors、深海迷航 (Subnautica) |

---

## Core Fantasy

你是一名深海打撈者，駕駛破舊的小船在未知海域作業。每次放下磁鐵都是一次賭博 — 你可能撈到值錢的金屬廢料，也可能遇到改變命運的神秘遺物。隨著裝備升級和新海域的解鎖，你逐漸揭開深海中隱藏的秘密。

核心情感承諾：**「再來一次下潛」的期待感** — 每一次磁鐵沉入水底都充滿未知和可能性。

---

## Unique Hook

像黃金礦工，**AND ALSO** 每次撈到稀有遺物會觸發 Roguelite 式的隨機升級選擇，讓同樣的海域每次玩起來都不一樣。4 分鐘的回合設計讓它完美適配手機碎片時間，但 Roguelite 層的深度讓硬核玩家也能找到樂趣。

---

## Player Experience Analysis (MDA Framework)

### Target Aesthetics (What the player FEELS)

| Aesthetic | Priority | How We Deliver It |
| ---- | ---- | ---- |
| **Sensation** (sensory pleasure) | 2 | 磁鐵入水音效、物件吸附的物理回饋、像素風水下視覺效果 |
| **Fantasy** (make-believe) | 4 | 深海打撈者的幻想，未知海域的神秘感 |
| **Narrative** (drama) | N/A | 無主線劇情，以世界觀氛圍為主 |
| **Challenge** (mastery) | 1 | 磁鐵操控技巧、時間壓力下的策略決策、升級路線優化 |
| **Fellowship** (social) | N/A | 單人遊戲 |
| **Discovery** (exploration) | 3 | 新海域解鎖、稀有遺物發現、升級組合探索 |
| **Expression** (creativity) | 5 | Roguelite 升級的 build 多樣性 |
| **Submission** (relaxation) | 6 | 短回合的低壓力重複遊玩 |

### Key Dynamics (Emergent player behaviors)

- 玩家會學習在 SINKING 階段精準操控磁鐵軌跡來瞄準高價值目標
- 玩家會根據已獲得的遺物升級來調整每一次下潛的策略
- 玩家會在「多撈幾次小物資」vs「瞄準深處大目標」之間權衡
- 玩家會研究哪些 Roguelite 升級組合能產生協同效應

### Core Mechanics (Systems we build)

1. **磁鐵狀態機 (MagnetStateMachine)** — IDLE → SINKING → RETRIEVING → CHECK，物理驅動的抓取核心
2. **物資生成系統** — 海底隨機分佈不同價值的金屬物件，稀有度和位置影響策略
3. **Roguelite 升級系統** — 遺物觸發三選一升級（船速、能力、物資重置等）
4. **永久進度系統** — 花錢升級基礎屬性 + 條件解鎖新內容
5. **回合計時系統** — 4 分鐘限時，時間壓力創造緊張感

---

## Player Motivation Profile

### Primary Psychological Needs Served

| Need | How This Game Satisfies It | Strength |
| ---- | ---- | ---- |
| **Autonomy** (freedom, meaningful choice) | 每次下潛的目標選擇、Roguelite 三選一升級、升級路線規劃 | Core |
| **Competence** (mastery, skill growth) | 磁鐵操控技巧提升、單局收益紀錄、解鎖更深海域 | Core |
| **Relatedness** (connection, belonging) | 排行榜（可選）、分享最佳 run | Minimal |

### Player Type Appeal (Bartle Taxonomy)

- [x] **Achievers** (goal completion, collection, progression) — 升級系統、解鎖新海域、收集遺物
- [x] **Explorers** (discovery, understanding systems) — 發現稀有遺物、探索升級組合協同效應
- [ ] **Socializers** — 單人遊戲，非主要受眾
- [ ] **Killers/Competitors** — 無 PvP，排行榜為可選功能

### Flow State Design

- **Onboarding curve**: 第一局只有基本操作（放磁鐵、回收），第二局引入物資兌換，第三局引入遺物和升級選擇
- **Difficulty scaling**: 新海域有更深的水域、更稀疏的物資分佈、更高價值的目標
- **Feedback clarity**: 金幣數字彈出、物資價值顏色編碼、升級效果即時視覺回饋
- **Recovery from failure**: 4 分鐘即可重來，永久升級保留進度，失敗成本極低

---

## Core Loop

### Moment-to-Moment (30 seconds)

操控磁鐵的一次完整下潛：
1. 移動船身到目標位置上方
2. 點擊釋放磁鐵，磁鐵受重力下沉
3. 滑動螢幕微調磁鐵 X 軸軌跡，瞄準目標
4. 碰到物件自動吸附
5. 長按螢幕啟動回收，磁鐵帶著物資上升
6. 到達水面，物資自動兌換

**內在滿足感來源**：物理模擬的重量感、吸附瞬間的回饋、「剛好夠到」的技巧感

### Short-Term (4 minutes = 1 round)

一個完整回合：
- 多次下潛循環（預計 4-6 次）
- 收集物資、兌換金錢
- 遇到遺物時觸發三選一 Roguelite 升級
- 升級改變後續下潛的策略
- 回合結束時結算總收益

### Session-Level (10-15 minutes = 2-3 rounds)

- 連續玩 2-3 局，累積金幣
- 在商店升級永久屬性（磁力強度、繩索長度、吸附上限）
- 嘗試解鎖新海域的條件
- 自然停止點：用完金幣升級後

### Long-Term Progression

- **花錢升級**：磁力強度、回收速度、吸附上限、船移動速度的基礎值
- **條件解鎖**：新海域（更深、更稀有的物資）、新磁鐵類型、新遺物種類
- 完成所有海域的探索為最終目標

### Retention Hooks

- **Curiosity**: 下一個海域有什麼新物資和遺物？
- **Investment**: 永久升級累積不會消失
- **Mastery**: 精準操控磁鐵的技巧持續成長
- **Roguelite 多樣性**: 每一局的遺物組合都不同，想嘗試新 build

---

## Game Pillars

### Pillar 1: 一次下潛的滿足感

每次放下磁鐵到回收完成的過程必須讓人感到「爽快」— 物理手感、音效回饋、視覺表現都服務於此。

*Design test*: 如果一個功能讓下潛過程更流暢有趣，加入；如果讓下潛過程變得繁瑣或等待，砍掉。

### Pillar 2: 4 分鐘就是一個完整體驗

每一局必須在 4 分鐘內提供完整的遊戲弧線（開始→成長→高潮→結算），不能有未完成感。

*Design test*: 如果一個系統需要超過一局才能體驗完整，它不適合放在局內 — 改為跨局永久系統。

### Pillar 3: 每一局都不一樣

Roguelite 升級和物資分佈的隨機性確保重玩性。兩次相同的 run 不應該產生相同的最優策略。

*Design test*: 如果玩家找到一個「永遠最優」的固定策略，說明隨機性或升級設計需要調整。

### Anti-Pillars (What This Game Is NOT)

- **NOT 敘事驅動**: 不投入劇情開發，世界觀通過物資描述和海域氛圍暗示即可
- **NOT 複雜操作**: 操控只需要點擊和滑動，不加入多指手勢或虛擬搖桿
- **NOT 長時間沉浸**: 不設計需要 30 分鐘以上才有意義的系統，不加入需要長時間等待的機制
- **NOT 社交競爭**: 不以 PvP 或社交功能為核心，排行榜為可選裝飾

---

## Inspiration and References

| Reference | What We Take From It | What We Do Differently | Why It Matters |
| ---- | ---- | ---- | ---- |
| 黃金礦工 (Gold Miner) | 拋鉤→抓取→回收的核心操作循環 | 加入物理模擬和 X 軸微操控，提升技巧上限 | 驗證了「抓取」玩法的內在滿足感 |
| Vampire Survivors | 短回合 Roguelite、三選一升級、session 設計 | 操作從自動射擊改為主動操控磁鐵，更有技巧性 | 驗證了短回合 Roguelite 在手機市場的成功 |
| Subnautica | 水下探索的氛圍感、深度帶來的壓迫感 | 2D 像素風簡化表現，聚焦在撈取而非生存 | 水下設定的情感吸引力 |

**Non-game inspirations**: 深海打撈紀錄片、磁鐵釣魚 (Magnet Fishing) YouTube 頻道 — 「你永遠不知道會撈到什麼」的期待感

---

## Target Player Profile

| Attribute | Detail |
| ---- | ---- |
| **Age range** | 16-35 |
| **Gaming experience** | Casual 到 Mid-core |
| **Time availability** | 通勤/等待時的 5-15 分鐘碎片時間 |
| **Platform preference** | 手機為主 |
| **Current games they play** | Vampire Survivors、弓箭傳說、Royal Match |
| **What they're looking for** | 碎片時間也能有策略深度和成長感的遊戲 |
| **What would turn them away** | 強制長時間遊玩、複雜操作、付費牆 |

---

## Technical Considerations

| Consideration | Assessment |
| ---- | ---- |
| **Engine** | Godot 4.3（已配置） |
| **Key Technical Challenges** | 磁鐵物理模擬手感、觸控操作的精準度、物資隨機分佈的平衡性 |
| **Art Style** | Pixel Art（像素風） |
| **Art Pipeline Complexity** | Low-Medium（像素角色 + 水下環境 tileset） |
| **Audio Needs** | Moderate（水下氛圍音樂 + 物理互動音效很重要） |
| **Networking** | None（純單機，排行榜可選） |
| **Content Volume** | 3-5 個海域、15-20 種物資、10-15 種遺物升級、5-8 種永久升級 |
| **Procedural Systems** | 每局物資位置隨機生成、遺物掉落隨機 |

---

## Risks and Open Questions

### Design Risks

- 4 分鐘內可能只有 4-6 次下潛，Roguelite 升級的影響感可能不足
- SINKING 階段的 X 軸微操在手機觸控上可能不夠精準，需要仔細調校
- 「每局都不一樣」的承諾需要足夠多的遺物/升級種類才能實現

### Technical Risks

- 物理模擬（磁鐵帶多個物件上升）的效能在手機上需要驗證
- PinJoint2D 連接多物件時的穩定性

### Market Risks

- 手機休閒市場競爭激烈，獲客成本高
- 「黃金礦工」類遊戲已有大量同質化產品，需要 Roguelite hook 的差異化足夠明顯

### Scope Risks

- 像素美術資產量（多海域、多物資類型）可能超出預期
- Roguelite 平衡調校是耗時的迭代工作

### Open Questions

- 遺物的出現頻率如何設定？太高會失去稀有感，太低會讓 Roguelite 層無存在感 — **需要原型測試**
- 觸控操作映射：SINKING 時的滑動操控要多靈敏？— **需要原型測試**
- 永久升級的數值曲線如何避免「升滿後無動力」？— **需要經濟系統設計**

---

## MVP Definition

**Core hypothesis**: 玩家會覺得磁鐵抓取的操作手感有趣，並且願意在 4 分鐘限時內重複遊玩以嘗試不同策略。

**Required for MVP**:
1. 磁鐵狀態機（IDLE → SINKING → RETRIEVING → CHECK）完整運作
2. 一個海域的隨機物資生成
3. 基本的金錢兌換和 1-2 項永久升級
4. 至少 3 種遺物的三選一 Roguelite 升級
5. 4 分鐘計時器和回合結算

**Explicitly NOT in MVP** (defer to later):
- 多海域和海域解鎖系統
- 完整的遺物/升級種類
- 音效和視覺 juice
- 排行榜
- 觸控操作優化（先用滑鼠驗證）

### Scope Tiers

| Tier | Content | Features | Timeline |
| ---- | ---- | ---- | ---- |
| **MVP** | 1 海域、5 種物資、3 種遺物 | 核心循環 + 基本升級 | 2-3 週 |
| **Vertical Slice** | 1 海域完整、10 種物資、8 種遺物 | 核心 + 永久升級 + Roguelite 完整 | 4-6 週 |
| **Alpha** | 3 海域、15 種物資、12 種遺物 | 全功能粗糙版 | 8-10 週 |
| **Full Vision** | 5 海域、20+ 種物資、15+ 種遺物 | 完整打磨版 | 14-18 週 |

---

## Magnet State Machine Reference

```
        [IDLE/AIMING]
        船上，A/D 移動
        點擊 → 釋放磁鐵
              │
              ▼
        [SINKING]
        重力下沉
        滑動 → X 軸微調
        Area2D 偵測 → 吸附物件
              │
              ▼ (長按觸發)
        [RETRIEVING]
        持續向上力道
        帶物件上升
              │
              ▼ (到達水面)
        [CHECK]
        物資 → 金錢
        遺物 → 三選一升級
              │
              ▼
        [IDLE/AIMING] (循環)
```

---

## Next Steps

- [ ] Get concept approval from creative-director
- [ ] Decompose concept into systems (`/map-systems`)
- [ ] Design magnet state machine system (`/design-system`)
- [ ] Design economy/progression system (`/design-system`)
- [ ] Prototype core loop (`/prototype magnet-grab`)
- [ ] Validate core loop with playtest (`/playtest-report`)
- [ ] Plan first milestone (`/sprint-plan new`)
