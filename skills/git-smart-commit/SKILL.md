---
name: git-smart-commit
description: 將雜亂的 git 變更，依功能邏輯自動拆分成多個有意義的 conventional commit
---

# Git Smart Commit — 智慧拆分提交

將目前所有 staged / unstaged 變更，依功能邏輯分群後，逐批 `git add` + `git commit`。

---

## 流程

### 1. 檢查變更狀態

執行以下指令取得完整變更清單：

```bash
git status --short
```

若沒有任何變更，告知使用者「目前沒有需要提交的變更」後結束。

接著取得所有變更的 diff 內容（用來判斷分群邏輯）：

```bash
git diff
git diff --cached
```

---

### 2. 分析並分群

根據以下維度，將檔案變更分成多個 **commit 群組**，每組代表一個獨立的邏輯單元：

#### 分群依據（優先順序）

| 優先級 | 維度 | 範例 |
|--------|------|------|
| 1 | **專案腳手架 / 設定檔** | `package.json`, `vite.config.*`, `.gitignore`, `README.md`, `tsconfig.json` |
| 2 | **資料層 / config data** | `src/data/*.js`, `src/constants/*`, `src/config/*` |
| 3 | **元件（按元件名稱分組）** | `src/components/Hero.jsx` + 對應測試 + 對應樣式 |
| 4 | **頁面 / 路由** | `src/pages/*`, `src/routes/*`, `src/App.jsx` |
| 5 | **全域樣式** | `src/index.css`, `src/styles/*`, `src/theme/*` |
| 6 | **工具 / hooks / 型別** | `src/utils/*`, `src/hooks/*`, `src/types/*` |
| 7 | **測試** | `__tests__/*`, `*.test.*`, `*.spec.*` |
| 8 | **文件 / 其他** | `docs/*`, `*.md`（非 README）, 其他雜項 |

#### 分群規則

- **同一元件的 JSX/TSX + CSS Module + 測試 → 歸為同一組**
- **相關的資料檔如果是為某個元件服務 → 可考慮合併或獨立**，取決於變更量
- **若某一組只有 1 個檔案且改動極小（< 5 行）→ 合併到最相關的鄰近組**
- **新增檔案用 `feat`，修改用 `fix` / `refactor` / `style`，效能相關調整用 `perf`**

---

### 3. 產出 Commit 計畫

在執行任何 git 操作之前，先列出計畫讓使用者確認：

```
📋 Commit 計畫（共 N 個 commit）

1. 🔨 refactor: 初始化專案設定與相依套件
   → package.json, vite.config.js, .gitignore

2. ✨ feat: 新增首頁各區塊的設定資料
   → src/data/navigation.js, src/data/hero.js, ...

3. ✨ feat: 新增 Navbar 元件（含 RWD 漢堡選單）
   → src/components/Navbar.jsx

...

確認執行？(Y/n)
```

使用 `notify_user` 工具向使用者展示計畫並等待確認。

---

### 4. 逐批執行 Commit

使用者確認後，對每一組依序執行：

```bash
git add <file1> <file2> ...
git commit -m "<emoji> <type>: <簡短描述>" -m "<選填，說明為什麼這樣改>"
```

#### Commit Message 格式

```
<emoji> <type>: <簡短描述>
<選填，說明為什麼這樣改的內文>
```

**type 與 emoji 對照表（僅能使用下列 emoji，不可自創或替換）：**

| emoji | type | 使用時機 |
|-------|------|---------|
| ✨ | `feat` | 新增功能、元件、頁面 |
| 🐛 | `fix` | 修復 bug |
| 🔨 | `refactor` | 重構程式碼（不改變行為） |
| 📝 | `docs` | 文件更新 |
| 🎨 | `style` | 樣式／格式調整（不影響邏輯） |
| ✅ | `test` | 新增或調整測試 |
| ⚡ | `perf` | 效能優化 |

**subject（簡短描述）規則：**
- 使用繁體中文
- 不超過 50 字
- 不以句號結尾
- 用「動詞開頭」：新增、調整、修正、移除、重構

**body（選填說明文字）規則：**
- 僅在需要說明「為什麼這樣改」時附加，單純描述「做了什麼」不需要 body
- 另起一行書寫，與標題以空行分隔
- 使用繁體中文，簡潔扼要即可，不需長篇說明

---

### 5. 確認結果

所有 commit 完成後，執行：

```bash
git log --oneline -20
```

將結果展示給使用者，確認所有 commit 都已正確建立。

---

## 邊界情況處理

- **有衝突或 merge 狀態**：提醒使用者先解決衝突，不執行任何操作
- **有 `.env` 或敏感檔案**：提醒使用者確認是否應被 gitignore，不自動提交
- **變更量極大（> 50 個檔案）**：先產出分組摘要，請使用者確認後再執行
- **使用者已有部分 staged 變更**：尊重已 staged 的狀態，將其視為一個獨立群組或合併到最相關的群組
