# Dual Codex and Claude Code Configuration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 將 `main` 整合為一次安裝即可同時支援 Codex 與 Claude Code 的單一設定來源。

**Architecture:** 保留 `skills/` 作為共用來源，將工具專用檔案分別移入 `codex/` 與 `claude/`，將安全 hook 實作集中到 `shared/hooks/`。兩個安裝腳本各自建立 Codex 與 Claude Code 的標準 symlink，兩邊共用同一份 hook 實作。

**Tech Stack:** Bash、PowerShell、Python 3、JSON、Git symlink、現有 unittest 測試。

**Spec:** `docs/superpowers/specs/2026-10-22-dual-codex-claude-config-design.md`

## Global Constraints

- 一次執行 `install.sh` 或 `install.ps1` 必須同時配置 Codex 與 Claude Code。
- `skills/` 只能保留一份共用來源，且必須同時連到 `~/.agents/skills` 與 `~/.claude/skills`。
- Codex 與 Claude Code 的全域指令、設定與 hook 註冊必須分開管理。
- 既有實體使用者檔案不得被刪除；建立 symlink 前必須 backup。
- 共用 hook 只維護一份實作，兩個工具透過各自的標準路徑引用它。
- 不把機器專屬 secret 或 local settings 納入版控。
- 每個任務完成後都要執行該任務指定的驗證命令。

## Review Focus

- 同一台機器上兩套設定同時存在時，任何一方的安裝不得覆蓋另一方的設定。
- 已有實體檔案、指向錯誤來源的 symlink 與 dangling symlink 都必須保留或安全修復。
- 兩個工具的 hook 註冊格式不同，但必須執行同一份 hook 實作。
- 同名 skill 在兩分支內容不同時，不得默默丟失其中一方的功能。
- Bash、PowerShell、JSON 與 Python 的驗證必須在未安裝另一個工具的環境中仍可進行。

---

### Task 1: 建立整合工作區並盤點分支內容

**Files:**
- Create: none
- Modify: none
- Test: none

**Interfaces:**
- Consumes: `main`, `codex`, `claude-code` 三個現有分支。
- Produces: 一個從 `main` 建立的整合工作分支，以及分支差異盤點結果。

- [ ] **Step 1: 建立隔離的整合分支**

從 `main` 建立例如 `integrate/codex-claude-code` 的工作分支；不要在 `main`、`codex` 或 `claude-code` 上直接修改。

- [ ] **Step 2: 盤點兩分支檔案與同名差異**

使用 `git diff --name-status main..codex`、`git diff --name-status main..claude-code` 與 `git diff codex claude-code`，記錄工具專用檔案、共用 skills 與同名檔案差異。

- [ ] **Step 3: 驗證工作區起點**

Run: `git status --short --branch`

Expected: 工作區乾淨，且目前位於整合分支。

---

### Task 2: 建立 shared / codex / claude 目錄邊界

**Files:**
- Create: `shared/hooks/guard-dangerous-commands.py`
- Create: `codex/AGENTS.md`
- Create: `codex/hooks/hooks.json`
- Create: `claude/CLAUDE.md`
- Create: `claude/settings.json`
- Create: `claude/output-styles/*`
- Create: `claude/ccstatusline/settings.json`
- Modify/Delete: current root-level tool-specific files after their contents are migrated

**Interfaces:**
- Consumes: `codex` 與 `claude-code` 分支的工具專用檔案。
- Produces: 不互相覆蓋的 Codex、Claude Code 與 shared 來源路徑。

- [ ] **Step 1: 建立目錄與移入 Codex 檔案**

將 Codex 分支的 `AGENTS.md`、Codex hook 註冊檔與 Codex 專用內容移入 `codex/`；保持 `AGENTS.md` 的內容不變，除非路徑引用必須更新。

- [ ] **Step 2: 建立 shared hook 唯一來源**

將 `guard-dangerous-commands.py` 的功能整合到 `shared/hooks/guard-dangerous-commands.py`。訊息文字改為工具中性的描述；保留既有危險指令匹配與 JSON deny 行為。

- [ ] **Step 3: 建立 Claude Code 來源檔**

將 `CLAUDE.md`、Claude Code 的 `settings.json`、四個 output styles 與 ccstatusline 設定移入 `claude/`，並將 `settings.json` 中的 hook 路徑改為 `~/.claude/hooks/guard-dangerous-commands.py`。

- [ ] **Step 4: 檢查工具專用檔案沒有殘留根目錄副本**

Run: `find . -maxdepth 2 -type f | sort`

Expected: 根目錄不再有工具專用的 `settings.json` 或 `CLAUDE.md`；repo-level `AGENTS.md` 若存在則保留，`skills/` 維持單一目錄。

---

### Task 3: 合併並驗證共用 skills

**Files:**
- Modify: `skills/**` 中兩分支同名且內容不同的檔案
- Create/Modify: only skill files required to resolve tool-specific paths
- Test: `tests/test_skills_layout.py`

**Interfaces:**
- Consumes: 兩分支的全部 skills。
- Produces: 可被 Codex 與 Claude Code 同時使用、不依賴單一工具路徑的 `skills/`。

- [ ] **Step 1: 建立 skills layout 測試**

在 `tests/test_skills_layout.py` 加入測試，確認 `skills/` 存在、每個頂層 skill 有 `SKILL.md`，且 shared skill 不引用已移除的根目錄工具專用檔案。

- [ ] **Step 2: 執行測試確認目前差異可被看見**

Run: `python3 -m unittest tests.test_skills_layout -v`

Expected: 新增的檢查在尚未完成搬移或合併時，至少能指出缺少的 layout / stale reference。

- [ ] **Step 3: 逐檔合併同名 skill**

以功能完整性為優先合併兩分支內容；若內容只是工具名稱、路徑或說明差異，改成工具中性文字。不要為了格式一致而修改無關內容。

- [ ] **Step 4: 執行 skills 測試**

Run: `python3 -m unittest tests.test_skills_layout -v`

Expected: PASS，所有共用 skill 結構完整且沒有 stale tool-specific references。

---

### Task 4: 重寫雙工具安裝腳本

**Files:**
- Modify: `install.sh`
- Modify: `install.ps1`
- Test: `tests/test_install.sh`
- Test: `tests/test_install.ps1` or equivalent static validation fixture

**Interfaces:**
- Consumes: `shared/`, `codex/`, `claude/` 與 `skills/` 來源路徑。
- Produces: 同時完成兩套設定的 symlink，並以非零狀態回報必要步驟失敗。

- [ ] **Step 1: 擴充安裝測試 fixture**

在隔離的 temporary HOME 中加入預期 symlink mapping 測試，覆蓋：shared skills、Codex AGENTS/hooks、Claude CLAUDE/settings/output-styles、ccstatusline 與兩個 hook 連結。

- [ ] **Step 2: 執行測試確認目前腳本失敗**

Run: `bash tests/test_install.sh`

Expected: FAIL，因現有腳本尚未安裝新的 shared / codex / claude 來源結構。

- [ ] **Step 3: 實作 Bash 安裝流程**

在 `install.sh` 中集中處理 `make_link`、backup、錯誤計數與平台 symlink 行為，並依序安裝兩個工具的所有必要來源。

- [ ] **Step 4: 實作 PowerShell 安裝流程**

讓 `install.ps1` 與 Bash 版本使用相同 mapping、backup 規則、失敗語意與重複執行行為；保留 Windows 權限與 symlink 特殊處理。

- [ ] **Step 5: 驗證安裝腳本**

Run: `bash tests/test_install.sh`

Expected: PASS，包含首次安裝、重複安裝、既有實體檔案 backup、錯誤 symlink backup 與兩套工具 mapping。

Run: `bash -n install.sh`

Expected: exit code 0。

---

### Task 5: 整合並驗證兩套 hook 註冊

**Files:**
- Modify: `codex/hooks/hooks.json`
- Modify: `claude/settings.json`
- Modify: `shared/hooks/guard-dangerous-commands.py`
- Test: existing hook tests and `tests/test_dual_hook_registration.py`

**Interfaces:**
- Consumes: shared hook implementation and each tool's registration format.
- Produces: Codex 與 Claude Code 都能從自己的標準路徑呼叫同一份 hook。

- [ ] **Step 1: 建立 hook registration 測試**

測試兩份設定都註冊 `guard-dangerous-commands.py`，且指向各自家目錄下的 hook symlink；測試 hook 對危險與安全輸入的輸出保持一致。

- [ ] **Step 2: 執行測試確認註冊尚未完成**

Run: `python3 -m unittest tests.test_dual_hook_registration -v`

Expected: FAIL，直到兩份設定與 shared hook 路徑完成整合。

- [ ] **Step 3: 完成兩套註冊格式**

Codex 使用 `codex/hooks/hooks.json` 的格式；Claude Code 使用 `claude/settings.json` 的 `hooks.PreToolUse` 格式。不要讓其中一方依賴另一方的設定檔。

- [ ] **Step 4: 執行 hook 測試**

Run: `python3 -m unittest discover -s tests -v`

Expected: PASS，既有測試與新增 registration 測試均通過。

---

### Task 6: 更新 README 與 repository 文件

**Files:**
- Modify: `README.md`
- Modify: `.gitignore`
- Create/Modify: `docs/superpowers/specs/2026-10-22-dual-codex-claude-config-design.md` only if implementation decisions require clarification

**Interfaces:**
- Consumes: final directory layout and installer mappings.
- Produces: 使用者能從 README 了解同時安裝、設定邊界與驗證方式。

- [ ] **Step 1: 更新 README 內容**

說明 repo 同時管理 Codex 與 Claude Code；列出 shared、Codex、Claude Code 的來源與目標 mapping；提供 macOS/Linux、Windows PowerShell 與 Git Bash/WSL 的單次安裝命令。

- [ ] **Step 2: 更新安全與 local 設定說明**

明確標示哪些設定進版控、哪些設定保留在使用者機器；說明兩個工具共用 skills 與 hook 實作，但使用各自的註冊檔。

- [ ] **Step 3: 驗證文件中的路徑**

Run: `rg -n 'settings.json|AGENTS.md|CLAUDE.md|\.codex|\.claude|output-styles|ccstatusline' README.md`

Expected: 文件中的 mapping 與實際安裝腳本完全一致，沒有舊的「只支援 Codex」或「只支援 Claude Code」說明。

---

### Task 7: 完整驗證與 merge readiness

**Files:**
- Modify: none unless verification exposes an implementation defect
- Test: all existing and new tests

**Interfaces:**
- Consumes: completed integration branch.
- Produces: 可合併回 `main` 的驗證證據與 merge summary。

- [ ] **Step 1: 執行所有自動化測試**

Run: `python3 -m unittest discover -s tests -v`

Expected: PASS。

- [ ] **Step 2: 執行腳本與 JSON 靜態檢查**

Run: `bash -n install.sh`

Run: `python3 -m json.tool codex/hooks/hooks.json >/dev/null`

Run: `python3 -m json.tool claude/settings.json >/dev/null`

Expected: 全部 exit code 0。

- [ ] **Step 3: 執行隔離安裝 smoke test**

在 temporary HOME 執行 `install.sh`，檢查兩套設定、shared skills 與兩個 hook symlink；再次執行並確認沒有不必要 backup。

- [ ] **Step 4: 檢查差異與 merge readiness**

Run: `git diff --check`

Run: `git status --short`

Expected: 沒有 whitespace error；除預期 implementation files 外沒有未追蹤或意外修改。

- [ ] **Step 5: 提交整合變更**

依功能拆成至少三個 commits：layout/config migration、installer and tests、documentation and verification。完成後提供 `main` 合併順序與任何剩餘手動檢查。
