# Dual Codex and Claude Code Configuration Design

## Goal

將 `main` 整合為同時支援 Codex 與 Claude Code 的單一設定來源；一次執行 `install.sh` 或 `install.ps1`，即可安裝兩套工具的專用設定與共用 skills。

## Scope

- 共用 `skills/`，同時提供給 Codex 與 Claude Code。
- 分離 Codex 與 Claude Code 的全域指令、hook 註冊與工具專用設定。
- 重寫跨平台安裝腳本，使其一次完成兩套設定的 symlink 安裝。
- 保留既有安全 hook 行為，讓兩個工具共用同一份 hook 實作。
- 補足兩套設定的安裝、symlink、JSON 與腳本驗證。

不在本次範圍內：修改使用者家目錄中既有的非 symlink 設定內容、管理每台機器專屬的 Codex 或 Claude Code secret、重新設計個別 skill 的功能。

## Architecture

```text
skills/                         # 共用 skills
shared/hooks/                   # 共用 hook 實作
codex/                          # Codex 專用來源檔
claude/                         # Claude Code 專用來源檔
install.sh / install.ps1       # 同時安裝兩套設定
```

安裝對應：

```text
skills/                         -> ~/.agents/skills
skills/                         -> ~/.claude/skills

codex/AGENTS.md                 -> ~/.codex/AGENTS.md
codex/hooks/                    -> ~/.codex/hooks
codex/hooks/hooks.json          -> ~/.codex/hooks.json

claude/CLAUDE.md                -> ~/.claude/CLAUDE.md
claude/settings.json            -> ~/.claude/settings.json
claude/output-styles/           -> ~/.claude/output-styles
claude/ccstatusline/settings.json
                                -> ~/.config/ccstatusline/settings.json

shared/hooks/guard-dangerous-commands.py
                                -> ~/.codex/hooks/guard-dangerous-commands.py
                                -> ~/.claude/hooks/guard-dangerous-commands.py
```

兩個工具各自透過自己的標準設定路徑引用 hook；repo 只維護一份 hook 實作。

## Configuration Boundaries

### Shared

- `skills/` 是兩個工具共用的唯一來源。
- `shared/hooks/guard-dangerous-commands.py` 是危險指令防護的唯一實作。

### Codex

- `codex/AGENTS.md`：Codex 全域行為規範。
- 根目錄 `AGENTS.md`：repo-level instructions；保留給在此 repo 工作的 agent，不作為使用者家目錄安裝來源。
- `codex/hooks/hooks.json`：Codex hook 註冊格式。
- `codex/hooks/`：Codex 使用的 hook 目錄與 hook symlink。

### Claude Code

- `claude/CLAUDE.md`：Claude Code 全域行為規範。
- `claude/settings.json`：Claude Code 權限、plugins、statusline 與 hook 註冊。
- `claude/output-styles/`：Claude Code output styles。
- `claude/ccstatusline/settings.json`：ccstatusline 排版設定。

根目錄不再放工具專用的 `settings.json` 或 `CLAUDE.md`；若根目錄 `AGENTS.md` 是 repo-level instructions，應保留，但不由 installer 直接安裝。

## Installation Behavior

`install.sh` 與 `install.ps1` 必須：

1. 從腳本自身位置解析 repo 根目錄。
2. 建立必要的父目錄。
3. 為 Codex 與 Claude Code 建立所有必要 symlink。
4. 既有實體檔案或資料夾先以 timestamp backup 保留。
5. 指向正確來源的既有 symlink 可安全重建。
6. 任一必要連結建立失敗時，以非零狀態結束。
7. 完成後驗證兩套設定與共用 skills 的目標存在。

安裝腳本不得刪除使用者既有的實體設定資料，也不得依賴另一個工具是否已安裝。

## Skill Integration

兩分支中的 skills 必須合併至 `skills/`。同名檔案若內容不同，逐檔保留較完整、與工具無關的版本；若差異涉及工具專用路徑或行為，應將工具專用內容移到 `codex/` 或 `claude/`，不要讓 shared skill 依賴單一工具。

## Verification

驗證必須涵蓋：

- Python hook 語法與危險指令案例。
- Codex 與 Claude Code JSON 設定可解析。
- Bash 語法檢查。
- PowerShell 安裝腳本的可檢查語法或靜態驗證。
- 安裝後兩套工具的必要 symlink 都存在且指向正確來源。
- `~/.agents/skills` 與 `~/.claude/skills` 指向同一個 repo `skills/`。
- 安裝腳本重複執行不產生不必要 backup。
- 既有 Codex hook 測試與 Claude 安裝測試通過。

## Migration Order

1. 從 `main` 建立整合分支。
2. 將 `codex` 與 `claude-code` 的內容匯入暫存區，避免直接覆蓋。
3. 建立 `shared/`、`codex/`、`claude/` 目錄並搬移工具專用檔案。
4. 合併並檢查所有 skills。
5. 重寫 `install.sh` 與 `install.ps1`。
6. 更新測試與 README。
7. 執行完整驗證。
8. 將整合分支合併回 `main`。

## Success Criteria

- `main` 同時支援 Codex 與 Claude Code。
- 單次安裝即可配置兩個工具。
- 共用 skills 僅維護一份。
- Codex 與 Claude Code 的專用設定互不覆蓋。
- 安全 hook 在兩個工具中都能被註冊與執行。
- 所有自動化測試與腳本驗證通過。
