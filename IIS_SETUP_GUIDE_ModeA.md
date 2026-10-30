# 流派 A：IIS 子應用程式 (/api) 部署說明

本模式適合前端與後端分開建置、分組維護，但對外由同一個 IIS 站台及 Port 對外服務的架構。

---

## 📁 部署包資料夾結構
```text
Deploy_ModeA_SubApp/
├── index.html                   <-- React SPA 入口頁
├── web.config                   <-- 主站台設定 (SPA URL Rewrite 排除 ^/api)
├── favicon.svg / icons.svg
├── assets/                      <-- React JS / CSS Chunks
└── api/                         <-- 後端 ASP.NET Core 8 Web API 發行檔
    ├── LabApi.dll
    ├── web.config               <-- AspNetCoreModuleV2 處理常式
    ├── appsettings.json
    └── ...
```

---

## ⚡ IIS 快速架設 3 步驟（30 秒完成）

### 步驟 1：建立主網站
1. 開啟 **IIS 管理員** (`inetmgr`)。
2. 左側在 **站台 (Sites)** 上按右鍵 -> **新增網站 (Add Website...)**：
   - **站台名稱**：`Lab-ModeA`
   - **實體路徑**：選取本目錄 `Deploy_ModeA_SubApp`
   - **通訊埠 (Port)**：例如 `8081`（或自訂）
   - **應用程式集區**：建議切換為 **無受控碼 (No Managed Code)**
3. 點擊 **確定**。

### 步驟 2：將 `/api` 資料夾轉為子應用程式
1. 在 IIS 左側樹狀圖展開 `Lab-ModeA`。
2. 看到資料夾圖示 `api`，在其上按右鍵 -> **轉換為應用程式 (Convert to Application)**。
3. 應用程式集區保持預設（或指定任一 .NET Core 集區），點擊 **確定**。
   *(此時 `api` 圖示會變成應用程式地球圖示)*

### 步驟 3：瀏覽器驗證
1. 打開瀏覽器訪問：`http://localhost:8081`
2. 畫面將顯示當前 `location.href` 為 `http://localhost:8081/`。
3. 點擊 **「測試呼叫後端 API (/api/hello)」** 按鈕：
   - 前端發出同源相對路徑請求 `/api/hello`。
   - IIS 透過子應用程式轉發至 ASP.NET Core，成功回傳 JSON 資料！
   - 零跨域 (CORS) 問題、零額外 Port 佔用。

---

## 🛡️ 核心防踩坑技術亮點
1. **防規則污染 (`inheritInChildApplications="false"`)**：
   主站台 `web.config` 將 `<system.webServer>` 包裹在 `<location path="." inheritInChildApplications="false">`，確保父層的 SPA URL Rewrite 規則不會繼承到子應用程式 `/api`，徹底避免 IIS 500.19 衝突。
2. **排除 API 路由 (`^/api(/.*)?$`)**：
   SPA Rewrite 規則明確排除 `/api` 開頭的路徑，避免 API 請求被意外 rewrite 成 `index.html`。
3. **雙向相容路由 (`/hello` & `/api/hello`)**：
   後端 `Program.cs` 同時對應 `/hello` 與 `/api/hello`，IIS 掛載為子應用程式時 `PathBase` 為 `/api`，請求自動命中 `/hello`，完美銜接。
