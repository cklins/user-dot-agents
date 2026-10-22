---
name: nextjs-api-postman-sync
description: 通用工具,把任一 Next.js App Router 專案的 REST API route(app/api/**/route.js)同步到 Postman collection,自動偵測該專案的路由結構、認證方式、回應格式與 API 命名慣例。當你剛完成或修改一個 Next.js API route,或要求「把這個 API 同步到 Postman」「建立 Postman request」「產生 Postman 測試 collection」時使用。與特定專案內建的客製版 postman sync skill 不同——本 skill 不預設任何專案寫死的慣例,第一次在某專案執行時會先跑一輪偵測並徵求確認。
---

把目前 Next.js 專案(App Router)的 API route 同步到 Postman collection。所有「這個專案的慣例是什麼」的假設都不寫死在這支 skill 裡——第一次在某個專案執行時,會先偵測、攤給你確認,才把結果寫進專案根目錄的 `postman-api-sync.config.json`;之後重跑直接讀這份設定檔,只做輕量一致性檢查。放在專案根目錄(而非 `.codex/` 底下)是刻意的——這份設定檔記錄的是專案本身的 API 慣例,不是 Codex 專屬資訊,其他 coding agent 也該讀得到、用得到。

## Step 0:載入或建立專案設定

檢查專案根目錄有沒有 `postman-api-sync.config.json`。

- **沒有(全新專案)**:讀 [DETECTION.md](./DETECTION.md),依序跑完裡面的 5 個偵測項目(路由框架、認證方式、response envelope、namespace 分組、環境清單),每一項都要先攤給使用者確認才寫入。全部完成後,把新產生的設定檔內容照 [CONFIG-SCHEMA.md](./CONFIG-SCHEMA.md) 的格式寫入專案根目錄的 `postman-api-sync.config.json`。
- **已存在**:讀入設定檔(格式見 [CONFIG-SCHEMA.md](./CONFIG-SCHEMA.md))。**不要**這時候就去讀整份 `DETECTION.md`——留到 Step 2 針對本次要處理的 route 做輕量一致性檢查時,才依需要讀取對應的小節。

完成判準:手上有一份可信的設定檔(剛偵測完成,或既有且尚未被判定過期)。

## Step 1:找出目標 route

找出剛新增或修改的 `route.js`(用 `git status`/`git diff` 檢查,或直接問是哪個 endpoint)。列出該檔案**所有**匯出的 HTTP method——`export const GET/POST/PUT/PATCH/DELETE = ...`——不只是第一個。

若設定檔的 `routes.framework` 不是 `app-router`,或找不到符合 `routes.globPattern` 的檔案,依 [DETECTION.md](./DETECTION.md) 的第 1 節處理。

完成判準:檔案中每一個匯出的 method 都已列出、沒有遺漏。

## Step 2:讀懂 API 合約 + 一致性檢查

- 路徑 = 檔案位置 + `routes.apiPathPrefix`。
- 對照設定檔的 `auth.scheme`、`responseEnvelope`,跑 [DETECTION.md](./DETECTION.md) 底部「輕量一致性檢查」那一節,確認這個 route 沒有偏離設定檔記錄的慣例。有落差就照該節指示處理(針對偏離的那一項重新偵測,或使用者確認是例外就繼續)。
- 若有 body,**不要**假設特定驗證函式庫——直接讀 handler 原始碼(不管用 Zod、Yup、手寫檢查,或只有 TS type)用語意理解推斷每個欄位的名稱、型別、必填與否、限制條件。
- 每個 route 是否需要認證,依設定檔 `auth.scheme` 判斷(`"none"` 就不需要)。

完成判準:對每個 method 都能講出完整路徑、是否需要認證、是否有 body,以及(若有)每個欄位的名稱/型別/限制,且已完成一致性檢查。

## Step 3:建立 happy-path 的 request body

每個欄位給一個代表該 endpoint「正常成功呼叫」情境的值——不是邊界值或極端值。用明顯是假資料的佔位值(`test@example.com`、`Utest1234567890`),絕不放真實個資。

完成判準:你的範例物件在語意上能通過 Step 2 推斷出的驗證規則,且每個值看起來就像一次真實成功呼叫會送出的內容。

## Step 4:確定目標 collection、namespace folder,並檢查是否重複

依 [POSTMAN-STRUCTURE.md](./POSTMAN-STRUCTURE.md) 的「找 collection」與「Namespace folder」兩節解析出:

- 目標 `collectionId`(新建或沿用既有)。
- 這個 endpoint 屬於哪個 namespace folder(或 `flat` 模式下不需要 folder)。
- 該 namespace folder(或根層)裡,這個 method+URL 是新建還是更新既有 item。

完成判準:明確講得出選定的 collection 及原因,以及本次是新建還是更新這支 request。

## Step 5:執行前先跟使用者確認計畫

在呼叫任何 create/update 工具之前,把計畫攤給使用者看:目標 collection、folder、request 名稱、method、URL、範例 body、(如果是本專案第一次執行)要建立的 Environment 清單與變數名稱。這是對使用者真實 Postman 帳號的寫入操作——先取得同意再動手。

完成判準:使用者已看過具體計畫並同意執行。

## Step 6:確保 collection 骨架、Environment、auth 都齊全

依 [POSTMAN-STRUCTURE.md](./POSTMAN-STRUCTURE.md) 的「Collection 根層 auth」與「Environment」兩節,確保:

- Namespace folder(若適用)存在。
- Collection 根層 auth 設定正確(讀 `{{<auth.variableName>}}`,`scheme: "none"` 則不設)。
- 設定檔 `environments` 列出的每個 Environment 都存在,變數名稱齊全,既有值 sticky 不覆蓋。若當前工具集不支援管理 Environment,依該節指示明確告知使用者。

完成判準:比對 [POSTMAN-STRUCTURE.md](./POSTMAN-STRUCTURE.md) 該節列出的每一項都已確認齊全。

## Step 7:新建或更新 request

依 [POSTMAN-STRUCTURE.md](./POSTMAN-STRUCTURE.md) 的「Request」一節,對 Step 1 列出的每個 method 各自建立/更新恰好一支 request(不分環境、不分 success/error 變體)。

寫入後把 item 讀回來,確認名稱/URL/header/body/測試腳本都確實落地,且沒有任何 sticky 欄位(body 值)被意外重設。

完成判準:每個 method 各自對應恰好一個 item,讀回來的內容跟預期一致。

## Step 8:回報結果

說明實際變更了什麼:collection/folder 名稱、每支 request 各自的名稱/method/URL、各自是新建還是更新,Step 6 是否新增了 Environment 或補上缺漏的變數名稱,以及(若本次是全新專案第一次執行)專案根目錄的 `postman-api-sync.config.json` 已建立、後續重跑會直接沿用。
