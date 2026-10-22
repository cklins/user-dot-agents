# 設定檔 Schema

每個使用本 skill 的專案,慣例都記錄在專案根目錄的 `postman-api-sync.config.json`(不放在 `.codex/` 底下,讓其他 coding agent 也能讀取)。這份檔案是**資料**,不是給人手寫的文件——由 skill 在偵測流程中產生與更新,使用者只在偵測流程詢問時「確認」內容,不直接編輯它(真的要改,刪掉整份檔案讓 skill 重新偵測即可)。

## 完整範例

```json
{
  "version": 1,
  "detectedAt": "2026-08-11",
  "routes": {
    "framework": "app-router",
    "globPattern": "src/app/api/**/route.js",
    "apiPathPrefix": "/api"
  },
  "auth": {
    "scheme": "bearer",
    "variableName": "apiKey",
    "headerName": "Authorization",
    "tokenSource": "Bearer <SrvApiKey.apiKey>,由 createApiHandler pipeline 驗證"
  },
  "responseEnvelope": {
    "detected": true,
    "successCondition": { "path": "response.success", "equals": true },
    "errorCodeCondition": { "path": "response.errorCode", "equals": "0" }
  },
  "namespaceGrouping": {
    "mode": "path-segment",
    "segmentIndex": 0
  },
  "environments": [
    { "name": "dev", "baseUrlVariable": "base_url" },
    { "name": "prod", "baseUrlVariable": "base_url" }
  ],
  "sharedIdentifierVariables": ["lineUid"],
  "collection": {
    "workspaceId": "w-xxxxx",
    "collectionId": "c-xxxxx",
    "name": "Cych Carbon Dashboard API"
  },
  "namespaceFolders": {
    "super8": "f-xxxxx",
    "line-user": "f-yyyyy"
  }
}
```

## 欄位說明

### `routes`

- `framework`:目前只會是 `"app-router"`(本 skill 不支援 Pages Router,見 `DETECTION.md`)。
- `globPattern`:第一次偵測時找到的 route 檔案 glob,例如 `src/app/api/**/route.js`。**不要**假設一定有版號層(`v1`)——這是偵測結果,不是預設值。
- `apiPathPrefix`:Postman request URL 組出來時的固定前綴,通常是 `/api`。

### `auth`

- `scheme`:`"bearer"` | `"apiKey"` | `"basic"` | `"none"`。**必須是全專案唯一一種**——偵測到 mixed 就不寫入這個欄位,轉而停下來問使用者(見 `DETECTION.md` 的 mixed-auth 處理)。
- `variableName`:Postman Environment 裡代表這個憑證的變數名稱,預設 `"apiKey"`,`scheme: "none"` 時整個 `auth` 物件可省略。
- `headerName`:只有 `scheme: "apiKey"`(非標準 `Authorization` header 的情況)才需要,記錄實際 header 名稱。
- `tokenSource`:純備註,描述這個 token 從哪來(哪張表、哪支 middleware),給人看的,不影響行為。

### `responseEnvelope`

- `detected: false` 時,物件只有這一個欄位,不生成 `pm.test`。
- `detected: true` 時,`successCondition`/`errorCodeCondition`(後者可省略,不是每個專案都有 error code 概念)各自是 `{ path, equals }`,`path` 是用 `.` 分隔的 response JSON 路徑(例如 `response.success`),`equals` 是期望值。

### `namespaceGrouping`

- `mode: "path-segment"`:用路徑的某一段當 folder 名稱,`segmentIndex` 指定是第幾段(從 `apiPathPrefix` 之後算起,0-indexed)。例如 `/api/super8/v1/taskList` 且 `apiPathPrefix: "/api"`、`segmentIndex: 0` → namespace 是 `super8`。
- `mode: "flat"`:不分 folder,所有 request 平鋪在 collection 根層。

### `environments`

陣列,每個元素是 `{ name, baseUrlVariable }`。**注意**:不同環境的 `baseUrlVariable` 名稱通常刻意設成同一個字串(如都叫 `"base_url"`)——因為變數名稱本身就是 Postman Environment 的 scope key,不同 Environment 各自定義同名變數的不同值,不需要靠變數名稱本身區分環境(不要沿用原版 `prod_base_url` 那種前綴命名法)。認證變數同理,一律用 `auth.variableName` 這一個名字,值隨 Environment 切換。

### `sharedIdentifierVariables`

字串陣列,只記錄「有哪些變數名稱」,實際值活在 Postman Environment 裡(sticky,不重複存在這份設定檔中,避免兩處資料源不一致)。

### `collection` / `namespaceFolders`

第一次執行 step 4/6(見 `SKILL.md`)解析出結果後快取的 id,用來讓重跑時跳過 workspace/collection 搜尋。**這只是快取,不是唯一真相**——每次使用前仍要用 id 呼叫對應的 `get` API 驗證還存在、內容還吻合,id 失效(404 或內容對不上)就當作快取過期,退回重新搜尋/建立。
