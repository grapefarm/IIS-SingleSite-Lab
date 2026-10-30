# 流派 B：Unified wwwroot (單一資料夾) 部署說明

本模式適合追求極簡運維、全由後端容器/進程一體化託管的架構。IIS 只需要建立一個普通站台，連「子應用程式」都不需要設定。

---

## 📁 部署包資料夾結構
```text
Deploy_ModeB_UnifiedWwwroot/
├── LabApi.dll                   <-- 後端主程式
├── LabApi.exe
├── web.config                   <-- AspNetCoreModuleV2 處理常式
├── appsettings.json
└── wwwroot/                     <-- 前端 React 打包輸出的靜態檔案
    ├── index.html
    ├── favicon.svg / icons.svg
    └── assets/
```

---

## ⚡ IIS 快速架設 2 步驟（15 秒完成）

### 步驟 1：建立主網站
1. 開啟 **IIS 管理員** (`inetmgr`)。
2. 左側在 **站台 (Sites)** 上按右鍵 -> **新增網站 (Add Website...)**：
   - **站台名稱**：`Lab-ModeB`
   - **實體路徑**：選取本目錄 `Deploy_ModeB_UnifiedWwwroot`
   - **通訊埠 (Port)**：例如 `8082`（或自訂）
   - **應用程式集區**：選取 **無受控碼 (No Managed Code)**
3. 點擊 **確定**。

### 步驟 2：瀏覽器驗證
1. 打開瀏覽器訪問：`http://localhost:8082`
2. 畫面將顯示當前 `location.href` 為 `http://localhost:8082/`。
3. 點擊 **「測試呼叫後端 API (/api/hello)」** 按鈕：
   - 前端發出同源相對路徑請求 `/api/hello`。
   - 直接命中 ASP.NET Core 的 `/api/hello` 端點，回傳 JSON 資料！
   - SPA 任意深層路由重整頁面，由 ASP.NET Core `MapFallbackToFile("index.html")` 原生處理。

---

## 🛡️ 核心防踩坑技術亮點
1. **完全免安裝 IIS URL Rewrite 模組**：
   靜態檔案由 ASP.NET Core `UseDefaultFiles()` 與 `UseStaticFiles()` 提供；SPA 路由 fallback 由 `MapFallbackToFile("index.html")` 內部處理，伺服器不用裝 IIS URL Rewrite 擴充套件。
2. **單一進程、單一組態檔**：
   只有後端一個 `web.config`，沒有巢狀站台的組態繼承問題，維護最單純。
