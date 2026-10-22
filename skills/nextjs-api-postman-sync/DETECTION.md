# 偵測流程

只有兩種情況會走到這份文件:專案根目錄還沒有 `postman-api-sync.config.json`(全新專案,完整跑一輪),或是 `SKILL.md` 的輕量一致性檢查發現對不上、使用者同意重新偵測(可以只重跑對得上的那個子項,不必整份重來)。**已有設定檔且一致性檢查通過的重跑,不要讀這份文件。**

每一項偵測都遵守同一個原則:**用語意理解讀程式碼,推斷出結果後一定要秀給使用者看、取得確認,才寫入設定檔。** 偵測本身可以錯,但錯誤不能無聲無息流進設定檔。

## 1. 路由框架與路徑慣例

找 `app/api/**/route.js` 或 `src/app/api/**/route.js`(依專案是否用 `src/` 目錄)。只認 App Router——如果專案是 Pages Router(`pages/api/**.js`,單一檔案 default export、內部用 `req.method` 手動分派),明確告知使用者「本 skill 目前只支援 App Router,偵測不到符合的 route 檔案」,不要嘗試硬解析 Pages Router 的結構。

找到的檔案裡,觀察路徑深度是否有版號層(`v1`、`v2`)或其他固定分段慣例,但**不要预設**一定有——單純如實記錄這個專案的實際結構到 `routes.globPattern`。

把找到的第一批 route 檔案路徑攤給使用者看:「偵測到的 API route 大概長這樣:`<例子路徑們>`,這樣對嗎?」確認後寫入 `routes` 欄位。

## 2. 認證方式

抽樣讀幾個(不必全部)route handler 或它們共用的 middleware/wrapper(例如專案裡如果有類似 `createApiHandler` 這種包一層的 helper,直接讀那個 helper 一次就夠,不用每個 route 都讀),判斷:

- 完全沒有認證檢查邏輯 → `scheme: "none"`。
- 檢查 `Authorization: Bearer <token>` → `scheme: "bearer"`。
- 檢查其他自訂 header(如 `X-API-Key`)→ `scheme: "apiKey"`,記下 `headerName`。
- Basic Auth → `scheme: "basic"`。

**檢查是否全專案一致**:抽樣至少涵蓋不同 namespace/資料夾底下的 route,如果同一個專案內不同 route 用不同認證方式(例如有些 public、有些需要 token),**不要**猜哪個該套用、也不要嘗試做 per-route 覆寫——直接停下來告訴使用者:「偵測到多種認證方式(route A 用 X,route B 用 Y),本 skill 目前只支援全專案統一一種認證,請確認要以哪一種為準,或先手動排除例外 route 後再重跑。」在使用者明確回覆前不寫入 `auth` 欄位、不繼續往下走。

確認後把 `scheme`(與 `headerName`,如適用)攤給使用者看一次再寫入設定檔。

## 3. Response envelope(給 `pm.test` 用)

找共用的 response 包裝函式(如果有的話,通常會有一個地方統一組出成功/失敗回應,類似 `actionSuccess()`/`actionError()` 或某個 `createApiHandler` 內部固定回傳的結構),或直接看兩三個 route 的成功回應寫法。嘗試歸納出一個**穩定重複出現**的結構,例如:

- 有沒有一個欄位固定代表「成功與否」(布林值或特定字串)?
- 有沒有一個欄位固定代表 error code?

歸納出來後,把範例 JSON 攤給使用者看:「這個專案的成功回應大概長這樣:`{...}`,我打算讓每支 request 的測試腳本斷言 `<path>` 等於 `<值>`,這樣可以嗎?」

- 使用者確認 → 寫入 `responseEnvelope.detected: true` 與對應的 `successCondition`/`errorCodeCondition`。
- 找不到穩定結構,或使用者說不準確 → 寫入 `responseEnvelope.detected: false`,之後 `POSTMAN-STRUCTURE.md` 的 step 7 就不會生成 `pm.test`。**不要**為了「至少有個測試」硬湊一個不確定的斷言。

## 4. Namespace 分組

觀察 `apiPathPrefix` 之後的路徑第一段(或普遍一致的某一段)是否代表有意義的業務分組(例如 `/api/super8/...`、`/api/line-user/...` 各自是不同的呼叫方/業務域)。

- 如果路徑段落本身就是有意義的分組(不是單純的資源 ID 或動詞)→ `namespaceGrouping.mode: "path-segment"`,記錄是第幾段(`segmentIndex`)。
- 如果專案 route 數量很少(個位數)或路徑結構本身就沒有清楚分組 → `namespaceGrouping.mode: "flat"`。

一樣攤給使用者看分組結果範例(「我打算把這些 route 分成 `super8`、`line-user` 兩個 folder,對嗎?」)再寫入。

## 5. 環境清單

問使用者:「這個 collection 要對應哪些環境?(例如 dev / prod,或 dev / staging / prod,或只要一個)」不要預設一定是兩個。每個環境只需要一個名稱,`baseUrlVariable` 固定用 `"base_url"`(所有環境共用同一個變數名稱,見 `CONFIG-SCHEMA.md` 的說明,不要學原版加 `prod_` 前綴)。

## 輕量一致性檢查(重跑時,不是全新偵測)

`SKILL.md` 每次處理一個 route 前,對照設定檔做以下比對(便宜、只針對這次要處理的單一 route,不必重新掃全專案):

- 這個 route 的認證檢查邏輯,是否符合 `auth.scheme`?
- 這個 route 的路徑,是否落在 `routes.globPattern` 描述的結構裡?
- 這個 route 的 response 寫法,是否還符合 `responseEnvelope`(如果 `detected: true`)?

任何一項對不上,停下來告知使用者具體是哪裡不符,問是否要針對**那一項**重新偵測(只重跑本文件對應的那一小節,不必整份 `postman-api-sync.config.json` 重來),或使用者確認「這個 route 本來就是例外,忽略」就繼續按原設定跑。
