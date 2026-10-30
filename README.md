# IIS 前後端分離「單一站台 (Single Port)」實驗專案

本實驗專案旨在示範並比較在 **Windows IIS** 環境下，將前端 SPA (React + Vite + TypeScript) 與後端 API (ASP.NET Core 8 Web API) 整合至**同一站台、同一通訊埠 (Single Port / Same Origin)** 的兩種主流部署實務：

1. **流派 A：IIS 子應用程式 (`/api`) 模式**
2. **流派 B：Unified wwwroot (單一資料夾) 模式**

---

## 🚀 專案結構

```text
IIS-SingleSite-Lab/
├── LabApi/                      # 後端 ASP.NET Core 8 Web API
│   ├── Program.cs               # 支援 /hello 與 /api/hello 雙路由 + 靜態檔託管
│   └── LabApi.csproj
│
├── lab-web/                     # 前端 React + Vite + TypeScript
│   ├── src/
│   │   ├── App.tsx              # 顯示 location.href 並發送相對路徑 /api/hello
│   │   └── App.css
│   └── public/
│       └── web.config           # 關鍵防衝突設定 (inheritInChildApplications="false")
│
├── build_lab.ps1                # 一鍵編譯與打包腳本
├── IIS_SETUP_GUIDE_ModeA.md     # 流派 A 詳細 30 秒架設指南
├── IIS_SETUP_GUIDE_ModeB.md     # 流派 B 詳細 15 秒架設指南
│
├── Deploy_ModeA_SubApp/         # [產出] 流派 A 部署包 (主站台 + api 子應用程式)
└── Deploy_ModeB_UnifiedWwwroot/ # [產出] 流派 B 部署包 (純單一資料夾)
```

---

## 📦 一鍵建置與打包

在專案根目錄執行 PowerShell 指令：

```powershell
.\build_lab.ps1
```

腳本會依序完成：
1. 編譯前端 React 生產版本 (`npm run build`)
2. 發行後端 ASP.NET Core 8 Web API (`dotnet publish -c Release`)
3. 自動產出 `Deploy_ModeA_SubApp` 與 `Deploy_ModeB_UnifiedWwwroot` 部署包，並附帶專屬說明。

---

## ⚡ 兩種流派 3 分鐘快速驗證指南

### 🅰️ 流派 A：IIS 子應用程式 (/api)

- **主站台實體路徑**：`Deploy_ModeA_SubApp`
- **架設步驟**：
  1. 開啟 IIS 管理員 (`inetmgr`)，新增網站 `Lab-ModeA`，實體路徑指向 `Deploy_ModeA_SubApp`，通訊埠設為 `8081`，集區設為「無受控碼」。
  2. 展開 `Lab-ModeA` 站台，在 `api` 資料夾按右鍵 -> **「轉換為應用程式」** -> 確定。
- **驗證網址**：`http://localhost:8081`
- **點擊按鈕**：前端發送相對路徑 `/api/hello`，子應用程式回傳 JSON！

---

### 🅱️ 流派 B：Unified wwwroot (單一資料夾)

- **主站台實體路徑**：`Deploy_ModeB_UnifiedWwwroot`
- **架設步驟**：
  1. 開啟 IIS 管理員 (`inetmgr`)，新增網站 `Lab-ModeB`，實體路徑指向 `Deploy_ModeB_UnifiedWwwroot`，通訊埠設為 `8082`，集區設為「無受控碼」-> 確定。
  2. 不需要任何子應用程式設定！
- **驗證網址**：`http://localhost:8082`
- **點擊按鈕**：前端發送相對路徑 `/api/hello`，由 ASP.NET Core 直接回傳 JSON！

---

## 💡 關鍵架構差異與防坑要點

| 評估項目 | 流派 A：IIS 子應用程式 (/api) | 流派 B：Unified wwwroot |
| :--- | :--- | :--- |
| **IIS 站台結構** | 主站台 (前端) + `/api` 子應用程式 (後端) | 純單一站台 (後端託管前端 wwwroot) |
| **IIS 設定複雜度** | 需額外按一次「轉換為應用程式」 | 零額外設定，選定路徑即完成 |
| **URL Rewrite 模組**| **必須安裝** (且須排除 `^/api`) | **完全不需要安裝** (由 C# 原生 Fallback) |
| **web.config 衝突風險** | 須加上 `inheritInChildApplications="false"` | 只有一個 `web.config`，零衝突可能 |
| **團隊分工情境** | 前後端分開建置與發布 | 前端打包後直接交由後端統一打包出版 |
