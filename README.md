# Presentation_skills（`presentation-skills`）

將 [docs/簡報技巧完整報告.pdf](./docs/簡報技巧完整報告.pdf)（施金波《04 簡報技巧》33 頁投影片、18 支教學影片方法論與 8 大實作／口說練習）完整萃取並封裝而成的跨 Agent 簡報設計與口頭表達 Skill／Plugin。

當任一已安裝此 Skill 的 Agent 處理**簡報相關內容**（製作或改寫投影片、規劃簡報大綱、資訊視覺化、撰寫提案 Pitch 稿、口頭報告講稿或講者備忘稿）時，會自動載入本方法論，並在回覆最開頭顯示：

```text
正在使用Presentation_skills製作簡報
```

---

## 目錄結構

```text
d:\Agent_Skill\Presentation_skills\
├── docs\
│   └── 簡報技巧完整報告.pdf                          # 原始 86 頁完整教材報告
├── presentation-skills\                             # Plugin / Skill 原始碼（Single Source of Truth）
│   ├── plugin.json                                  # Antigravity Plugin 設定檔
│   ├── rules\
│   │   └── AGENTS.md                                # 常駐觸發規則（自動啟用與啟動宣告）
│   └── skills\
│       └── presentation-skills\
│           ├── SKILL.md                             # 主技能檔（標準工作流、輸出結構、7 大避雷檢核）
│           └── references\                          # 漸進式揭露（Progressive Disclosure）參考庫
│               ├── 01-common-mistakes.md            # Slide 4–5：七大致命傷診斷與根治
│               ├── 02-aesthetics.md                 # Slide 6–8：美感訓練三步驟、雜誌風改造、亮暗背景決策
│               ├── 03-information-backbone.md       # Slide 9：排版前整理資訊主幹與圖解原型
│               ├── 04-visualization.md              # Slide 11, 13–17, 20：條列兩招、長文降噪、三大起手式、三合一
│               ├── 05-logic-pyramid-scqa.md         # Slide 23, 24, 26, 28：講重點、金字塔原理、條列口說、SCQA
│               ├── 06-pitch-and-delivery.md         # Slide 30–33：提案力實戰、舞台肢體氣場、不背稿三招
│               ├── 07-worked-examples.md            # 練習 1–8：完整原題條件與 Before/After 參考示範解法
│               └── sources.md                       # 課程出處與 18 支教學影片連結及建議觀看區段
├── scripts\
│   └── validate_skill.py                            # 結構、Frontmatter、連結與編碼自動驗證腳本
├── install.ps1                                      # 一鍵安裝腳本（預設安裝至 Antigravity）
└── uninstall.ps1                                    # 一鍵移除腳本
```

---

## 安裝與更新方式

### 1. 預設安裝（僅安裝至 Antigravity）

在 PowerShell 執行：

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

這會將整包 `presentation-skills` Plugin（含 `skills/presentation-skills/` 與 `rules/AGENTS.md`）複製到：
- `~/.gemini/config/plugins/presentation-skills`

> **為何 Antigravity 採用 Plugin 封裝？**
> Antigravity 同時讀取 Plugin 內的 `skills/` 與常駐 `rules/AGENTS.md`，不僅讓簡報任務 100% 穩定觸發並顯示「正在使用Presentation_skills製作簡報」，且完全不會污染其他 CLI 共用的 `~/.gemini/GEMINI.md`。

### 2. 擴充安裝至其他 Agent（Gemini CLI、Claude Code、Codex 等）

若日後需要安裝到本機其他 Agent，可透過 `-Targets` 參數指定：

```powershell
# 同時安裝到 Antigravity、Gemini CLI 與 Claude Code
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Targets antigravity,gemini-cli,claude-code

# 安裝到所有支援的目標（含 Codex 與通用 ~/.agents/skills）
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Targets antigravity,gemini-cli,claude-code,codex,agents
```

各目標對應的安裝路徑如下：

| 目標名稱 (`-Targets`) | Skill / Plugin 安裝路徑 | 全域觸發規則寫入位置（含可逆標記區塊） |
| :--- | :--- | :--- |
| `antigravity` *(預設)* | `~/.gemini/config/plugins/presentation-skills/` | 內建於 Plugin 的 `rules/AGENTS.md` |
| `gemini-cli` | `~/.gemini/skills/presentation-skills/` | `~/.gemini/GEMINI.md` |
| `claude-code` | `~/.claude/skills/presentation-skills/` | `~/.claude/CLAUDE.md` |
| `codex` | `~/.codex/skills/presentation-skills/` | `~/.codex/AGENTS.md` |
| `agents` | `~/.agents/skills/presentation-skills/` | 無（僅複製標準 `SKILL.md` 目錄） |

- 若希望以目錄連結（Junction）取代複製（修改原始檔即同步生效），可加上 `-Link`。
- 若不想修改全域指令檔（`GEMINI.md`／`CLAUDE.md`），可加上 `-NoRules`。

### 3. 解除安裝

```powershell
# 預設移除 Antigravity 上的安裝
powershell -ExecutionPolicy Bypass -File .\uninstall.ps1

# 移除多個指定目標（並自動清理全域指令檔中的標記區塊）
powershell -ExecutionPolicy Bypass -File .\uninstall.ps1 -Targets antigravity,gemini-cli,claude-code
```

---

## 驗證方式

執行驗證腳本檢查 YAML Frontmatter、啟動宣告字串、內部相對連結、檔案大小與字元正規化：

```powershell
python .\scripts\validate_skill.py
```
