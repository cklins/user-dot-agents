# Postman 結構規則

這份文件定義「設定檔裡的慣例」要怎麼落地成實際的 Postman collection / folder / environment / request。`SKILL.md` 在對應步驟會指到這裡的小節。

絕不擅自新增 collection、workspace 或跟本次任務無關的東西——Postman 的變更會外顯於這個 repo 之外,且難以乾淨復原。任何 create/update 呼叫之前,一律先把計畫(collection、folder、environment、request 名稱/method/URL/範例 body)攤給使用者看、取得同意才動手,這是不可省略的步驟。

## 找 collection(對應設定檔的 `collection` 欄位)

- 設定檔已有 `collection.collectionId` → 呼叫 `getCollection` 驗證還存在且內容吻合;失敗就當快取失效,退回下面的搜尋流程。
- 沒有快取或快取失效 → 把專案名稱/`routes.apiPathPrefix` 相關關鍵字正規化,在使用者所有 workspace 搜尋名稱相符的 collection(不分大小寫/空格):`getWorkspaces` 帶 `createdBy=<me.user.id>` → 對每個 workspace 呼叫 `getCollections`。
  - 剛好一個相符 → 採用,寫回 `collection` 欄位。
  - 零個或多個候選 → 問使用者要用哪一個,或是否新建。不要用猜的。

## Namespace folder(對應 `namespaceGrouping`)

- `mode: "flat"` → 不建 folder,request 直接掛在 collection 根層,跳過本節其餘部分。
- `mode: "path-segment"` → 對每個要處理的 endpoint,算出它的 namespace(依 `segmentIndex` 那一段路徑)。
  - 查 `namespaceFolders` 快取有沒有這個 namespace 的 folder id → 有就用 `getCollection`(`model=full`)驗證還在。
  - 沒有快取或快取失效 → 對 collection 目前的 folder 清單做名稱比對(不分大小寫);找到就採用,沒找到才新建(`putCollection`,在根層 `item` 加入 `{ "name": "<namespace>", "item": [] }`),記下新 id 存回 `namespaceFolders`。
- **查重範圍**:同一個 namespace folder 底下,用 method+URL 比對(不是只看名稱)有沒有已存在的 item——因為新設計下一個 endpoint 只對應**一支** request(不像原版要分別查 dev/prod 兩個 folder),查重只需要在目標 namespace folder 內做一次。

## Collection 根層 auth

- `auth.scheme: "none"` → collection 根層不設 `auth`,request 也不帶。
- 其他 scheme → collection 根層 `auth` 讀 `{{<auth.variableName>}}`(預設變數名 `apiKey`):
  - `"bearer"` → `{ "type": "bearer", "bearer": [{ "key": "token", "value": "{{apiKey}}", "type": "string" }] }`
  - `"apiKey"` → `{ "type": "apikey", "apikey": [{ "key": "key", "value": "<headerName>" }, { "key": "value", "value": "{{apiKey}}" }, { "key": "in", "value": "header" }] }`
  - `"basic"` → `{ "type": "basic", "basic": [...] }`,變數同理讀 Environment 值。

所有 request 都**不**自己帶 `auth` 或手動塞 `Authorization` header——一律繼承 collection 根層,值隨目前選取的 Postman Environment 切換。**這一點跟原版不同**:原版因為用 folder 分 dev/prod、而 folder 層級不能設 auth,所以 `prod` 底下每支 request 得自己覆寫一份 auth。現在改用原生 Environment,同一個變數名稱在不同 Environment 各自有值,collection 根層這一份 auth 設定就夠了,不需要、也不應該再讓任何 request 自帶 auth 覆寫。

## Environment(對應 `environments`,取代原版的 dev/prod folder)

對 `environments` 陣列裡每個 `{ name, baseUrlVariable }`:

- 用 Postman Environment 管理工具(`getEnvironments` 等)在同一個 workspace 裡搜尋名稱相符的 Environment(建議命名 `"<collection 名稱> - <name>"`,例如 `"Cych Carbon Dashboard API - dev"`)。
- 找不到 → 建立新的,初始只放變數**名稱**,值一律留空:
  - `base_url`(空字串)
  - `auth.variableName`(如 `apiKey`,空字串,`scheme: "none"` 時不需要這個變數)
  - 每個 `sharedIdentifierVariables` 裡的名稱(空字串)
- 找到既有的 → 讀出目前的變數值。**每個變數的值都是 sticky**:已經是非空值(不管是使用者填的還是前次執行留下的)絕不覆蓋;只補上缺少的變數名稱(值留空)。不同 Environment 之間的 sticky 狀態各自獨立——`dev` 環境的 `lineUid` 被改過,不代表 `prod` 環境也要跟著動。
- **如果目前的工具集沒有 Environment 相關的建立/更新能力**:明確告知使用者「本次執行環境偵測不到 Postman Environment 管理工具,請手動建立以下 Environment 並填入對應變數名稱:`<清單>`」,不要嘗試把值改塞進 collection variable 之類的變通方式假裝完成了這件事。

Environment 變數不像 secret 類型會被遮罩——只要有這個 collection/workspace 存取權的人都能看到明文。第一次建立時要提醒使用者這件事,尤其是代表正式環境憑證的變數。

## Request(一個 endpoint 對應 collection 裡恰好一支 request)

依 `SKILL.md` step 1 列出的每個匯出 method,在目標 folder(或根層,`flat` 模式)裡對應**恰好一支** request——不拆成多支 success/error/variant,也不再像原版一樣每個 endpoint 建兩支(dev/prod 各一);環境差異完全交給 Postman Environment 切換处理。

- **名稱**:固定格式 `"<METHOD> <apiPathPrefix><完整路徑> — <一句話功能描述>"`,例如 `"POST /api/super8/v1/taskList — 建立任務"`。這是全域固定的命名骨架,不進偵測流程(見 `SKILL.md` 決策)。
- **URL**:`{{base_url}}<apiPathPrefix><完整路徑>`,只有一份,不分環境。
- **Headers**:不帶 `Authorization`(走 collection auth);有 body 就加 `Content-Type: application/json`。
- **Body**:`dataMode: "raw"`,`dataOptions.raw.language: "json"`。`sharedIdentifierVariables` 裡的欄位寫成 `{{fieldName}}`,其餘欄位用當次算出的 happy-path 值(見 `SKILL.md` step 3)。**Body 欄位值也是 sticky**:
  - 沒有既有 item(新建)→ 全部欄位填 happy-path 值。
  - 已有既有 item(更新)→ 保留既有非空值,只補既有 body 裡是空值或缺漏的欄位。絕不把已有真實資料的欄位重設回佔位值。
- **測試腳本**:只有 `responseEnvelope.detected: true` 才生成,依 `successCondition`/`errorCodeCondition` 組出斷言,例如:

```js
pm.test('status is success', () => {
  const json = pm.response.json();
  pm.expect(json.response.success).to.be.true;
  pm.expect(json.response.errorCode).to.eql('0');
});
```

`detected: false` 時完全不加 `events`/`test` 區塊,不要用猜的斷言。

名稱、method、URL、header、測試腳本都是 skill 自己管理的骨架,即使是更新既有 request 也一律依這裡的規則重新對齊——只有 body 欄位值(前述)遵循 sticky 規則。

對每個 folder(或根層):沒找到既有 item 用 `createCollectionRequest`,找到就用 `updateCollectionRequest`。寫入後把 item 讀回來,確認名稱/header/auth(應為空,不帶覆寫)/body/測試腳本都確實落地,且沒有任何 sticky 欄位被重設——工具呼叫成功不代表內容正確。

## 已知工具限制

透過 `createCollection` 在一次呼叫裡連 folder 一起新建巢狀 item 時,item 上的 `event`(測試腳本)可能被靜默吃掉,即使傳入的 payload 是對的。遇到這個情況,對受影響的 item 個別呼叫 `updateCollectionRequest` 補上 `events`,再讀回確認才算完成——不要假設一次到位。
