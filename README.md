# user-dot-agents

> 集中版控 Codex 與 Claude Code 的使用者層級設定；共用 skills，工具專用設定分開管理，再以 symlink 連回各自的家目錄。

## 內容

```text
skills/                         # Codex 與 Claude Code 共用
shared/hooks/                   # 共用安全 hook 實作
codex/                          # AGENTS.md 與 Codex hook 註冊
claude/                         # CLAUDE.md、settings、output styles
install.sh / install.ps1       # 一次安裝兩套設定
```

`skills/` 只維護一份，會同時提供給 `~/.agents/skills` 與 `~/.claude/skills`。安全 hook 也只維護一份；Codex 與 Claude Code 透過各自的標準設定檔註冊它。

根目錄 `AGENTS.md` 是本 repo 的 project instructions；Codex 使用者層級指令來源則是 `codex/AGENTS.md`。

## Skills

| Skill | 簡介 |
| --- | --- |
| [`ask-matt`](skills/ask-matt/) | 根據情境推薦適合使用的 skill 或工作流程。 |
| [`baoyu-infographic`](skills/baoyu-infographic/) | 生成專業資訊圖表，支援多種版型與視覺風格。 |
| [`code-review-matt`](skills/code-review-matt/) | 從 Standards 與 Spec 兩個面向審查指定範圍的程式變更。 |
| [`codebase-design`](skills/codebase-design/) | 使用深模組、介面與 seam 等詞彙改善模組設計。 |
| [`diagnosing-bugs`](skills/diagnosing-bugs/) | 以重現、縮小範圍、驗證假設的迴圈診斷複雜 bug 或效能退化。 |
| [`domain-modeling`](skills/domain-modeling/) | 建立與打磨專案的 domain terminology、glossary 與 ADR。 |
| [`explanation-artifact`](skills/explanation-artifact/) | 透過四階段訪談產生可放入 README 或作品集的理解說明文件。 |
| [`explanation-workpage`](skills/explanation-workpage/) | 將 explanation artifact 轉成含 inline SVG 的自包含 HTML workpage。 |
| [`find-skills`](skills/find-skills/) | 協助探索、尋找與安裝可能適用的 skills。 |
| [`frontend-design`](skills/frontend-design/) | 建立具有辨識度、production-grade 的前端介面。 |
| [`git-branch-name`](skills/git-branch-name/) | 根據目前變更產生 kebab-case feature branch 名稱並建立分支。 |
| [`git-pr-description`](skills/git-pr-description/) | 根據 branch 差異產生 Pull Request title 與 description。 |
| [`git-smart-commit`](skills/git-smart-commit/) | 將雜亂變更依功能拆成有意義的 conventional commits。 |
| [`grill-me`](skills/grill-me/) | 透過連續追問釐清計畫或設計。 |
| [`grill-with-docs`](skills/grill-with-docs/) | 透過訪談釐清設計，同步建立 ADR 與 glossary 文件。 |
| [`grilling`](skills/grilling/) | 對計畫、決策或想法進行嚴格的壓力測試。 |
| [`handoff`](skills/handoff/) | 將目前對話濃縮成可交給另一個 agent/session 的交接文件。 |
| [`illustrated-slides-with-nano-banana`](skills/illustrated-slides-with-nano-banana/) | 產生每頁皆為完整 AI 圖像的 PowerPoint / PDF 簡報。 |
| [`fluxa-agent-wallet`](skills/illustrated-slides-with-nano-banana/fluxa-wallet/) | 透過 FluxA CLI 處理 x402 付款、USDC payout 與 payment link。 |
| [`implement`](skills/implement/) | 依據 spec 或 tickets 實作功能，並搭配測試與 review。 |
| [`improve-codebase-architecture`](skills/improve-codebase-architecture/) | 掃描 codebase 找出可深化的架構機會並產生視覺化報告。 |
| [`nextjs-api-postman-sync`](skills/nextjs-api-postman-sync/) | 偵測 Next.js App Router API 並同步建立 Postman collection。 |
| [`prototype`](skills/prototype/) | 建立一次性 prototype，快速驗證邏輯或 UI 設計問題。 |
| [`research`](skills/research/) | 針對問題查找高信度一手資料並整理成有引用的 Markdown。 |
| [`resolving-merge-conflicts`](skills/resolving-merge-conflicts/) | 協助依照雙方意圖解決進行中的 merge 或 rebase conflict。 |
| [`setup-matt-pocock-skills`](skills/setup-matt-pocock-skills/) | 初始化 issue tracker、triage labels 與 domain 文件結構。 |
| [`tdd`](skills/tdd/) | 以 red-green-refactor 執行測試驅動開發。 |
| [`teach`](skills/teach/) | 在多次對話中以工作區狀態教學一個新主題。 |
| [`to-spec`](skills/to-spec/) | 將目前對話整理成 spec，並發佈到專案 issue tracker。 |
| [`to-tickets`](skills/to-tickets/) | 將 spec 或 plan 拆成具有 blocking edges 的 tracer-bullet tickets。 |
| [`triage`](skills/triage/) | 將 issue 經過分類、驗證、追問與 brief 產生的 triage 流程。 |
| [`wayfinder`](skills/wayfinder/) | 將大型、跨 session 的工作拆成決策 ticket 地圖。 |
| [`writing-great-skills`](skills/writing-great-skills/) | 撰寫與編輯可預測、高品質 skill 的參考指南。 |

## 安裝

macOS / Linux：

```bash
git clone https://github.com/deancourse/user-dot-agents.git
cd user-dot-agents
bash install.sh
```

Windows PowerShell：

```powershell
git clone https://github.com/deancourse/user-dot-agents.git
cd user-dot-agents
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

Windows 建立 symlink 需要開啟「開發人員模式」或使用管理員權限。`install.ps1` 預設會在必要時要求 UAC；加上 `-NoElevate` 則改為開啟開發人員模式設定頁。

## Symlink 對應

| Repo 來源 | 安裝目標 |
| --- | --- |
| `skills/` | `~/.agents/skills` |
| `skills/` | `~/.claude/skills` |
| `shared/hooks/` | `~/.codex/hooks` |
| `shared/hooks/` | `~/.claude/hooks` |
| `codex/hooks/hooks.json` | `~/.codex/hooks.json` |
| `codex/AGENTS.md` | `~/.codex/AGENTS.md` |
| `claude/settings.json` | `~/.claude/settings.json` |
| `claude/CLAUDE.md` | `~/.claude/CLAUDE.md` |
| `claude/output-styles/` | `~/.claude/output-styles` |
| `claude/ccstatusline/settings.json` | `~/.config/ccstatusline/settings.json` |

安裝腳本具備以下行為：

- 既有實體檔案或資料夾先備份為 `*.backup-<timestamp>`。
- 已指向正確來源的 symlink 可重複安裝，不會產生多餘 backup。
- 指向錯誤來源的 symlink 會先保留備份，再建立正確連結。
- 任一必要連結失敗時，以非零狀態結束。

## Hook trust

安裝 hook 不等於授權執行。首次安裝後，請在 Codex 與 Claude Code 各自 review hook 註冊與 matcher，再確認信任。hook 對 malformed JSON 採 fail-open，避免 guard 故障導致所有工具被阻斷。

## 開發驗證

```bash
python3 -m unittest discover -s tests -v
bash -n install.sh
python3 -m json.tool codex/hooks/hooks.json >/dev/null
python3 -m json.tool claude/settings.json >/dev/null
```

`tests/test_install.sh` 會在 temporary HOME 中驗證兩套 symlink、backup 與重複安裝行為。PowerShell 安裝腳本應在 Windows PowerShell 或 `pwsh` 環境中另外執行 smoke test。

## Local-only 設定

以下設定不進版控：

- `~/.codex/config.toml`
- Claude Code 的 `settings.local.json`
- 安裝腳本產生的 `*.backup-*`

## License

本 Repo 以 [MIT License](LICENSE) 釋出；第三方 skill 以各目錄內的授權聲明為準。
