import { useState } from 'react'
import './App.css'

interface ApiResponse {
  message: string
  serverTime: string
  machineName: string
}

function App() {
  const [data, setData] = useState<ApiResponse | null>(null)
  const [loading, setLoading] = useState<boolean>(false)
  const [error, setError] = useState<string | null>(null)
  const [requestTimestamp, setRequestTimestamp] = useState<string | null>(null)

  const callApi = async () => {
    setLoading(true)
    setError(null)
    setData(null)
    setRequestTimestamp(new Date().toLocaleTimeString())

    try {
      // 呼叫相對路徑 /api/hello（完全不指定 IP 與 Port，同源共享 IIS 站台 Port）
      const response = await fetch('/api/hello')
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`)
      }
      const json: ApiResponse = await response.json()
      setData(json)
    } catch (err: unknown) {
      if (err instanceof Error) {
        setError(err.message)
      } else {
        setError('未知錯誤發生')
      }
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="container">
      <div className="card header-card">
        <div className="badge">IIS Single-Site Lab</div>
        <h1>前後端分離「單一站台 (Single Port)」實驗環境</h1>
        <p className="subtitle">
          React (Vite) 前端 + ASP.NET Core 8 Web API 共用同一 IIS 站台與通訊埠
        </p>
      </div>

      <div className="grid">
        {/* 瀏覽器環境資訊 */}
        <div className="card">
          <h2>🌐 瀏覽器站台環境 (Client Environment)</h2>
          <div className="info-list">
            <div className="info-item">
              <span className="label">當前網址 (location.href)</span>
              <code className="val">{window.location.href}</code>
            </div>
            <div className="info-item">
              <span className="label">同源站台 (location.origin)</span>
              <code className="val">{window.location.origin}</code>
            </div>
            <div className="info-item">
              <span className="label">通訊埠 (location.port)</span>
              <code className="val">{window.location.port || '80 (預設)'}</code>
            </div>
            <div className="info-item">
              <span className="label">API 請求目標</span>
              <code className="val highlight">相對路徑 /api/hello (零 CORS 限制)</code>
            </div>
          </div>

          <div style={{ marginTop: '1.5rem' }}>
            <button 
              className="btn-primary" 
              onClick={callApi} 
              disabled={loading}
            >
              {loading ? '連線中...' : '🚀 測試呼叫後端 API (/api/hello)'}
            </button>
          </div>
        </div>

        {/* 呼叫結果回應 */}
        <div className="card">
          <h2>📡 API 呼叫結果回應 (API Response)</h2>
          
          {loading && (
            <div className="status-box loading">
              <div className="spinner"></div>
              <span>正在向 C# 後端發送請求...</span>
            </div>
          )}

          {error && (
            <div className="status-box error">
              <strong>❌ 呼叫失敗：</strong>
              <p>{error}</p>
              <small>請確認 IIS 站台與 /api 子應用程式（或 unified wwwroot）已正確啟動。</small>
            </div>
          )}

          {data && (
            <div className="status-box success">
              <div className="success-header">
                <span className="dot online"></span>
                <strong>連線成功！後端回應內容：</strong>
                {requestTimestamp && <span className="time">請求時間: {requestTimestamp}</span>}
              </div>
              <pre className="json-box">
                {JSON.stringify(data, null, 2)}
              </pre>
              <div className="res-details">
                <div>💬 <strong>訊息:</strong> {data.message}</div>
                <div>⏰ <strong>伺服器時間:</strong> {data.serverTime}</div>
                <div>🖥️ <strong>主機名稱:</strong> {data.machineName}</div>
              </div>
            </div>
          )}

          {!loading && !error && !data && (
            <div className="status-box placeholder">
              點擊左側「測試呼叫後端 API」按鈕，立即驗證單一站台同源請求。
            </div>
          )}
        </div>
      </div>

      {/* 兩種部署模式說明 */}
      <div className="card footer-card">
        <h3>💡 支援的兩種 IIS 單一站台架構：</h3>
        <div className="modes-comparison">
          <div className="mode-col">
            <span className="mode-tag tag-a">流派 A：IIS 子應用程式 (/api)</span>
            <ul>
              <li><strong>主站台 (Root)：</strong>React 前端 (dist 資料夾) + 專屬 <code>web.config</code></li>
              <li><strong>防衝突機制：</strong><code>inheritInChildApplications="false"</code> 避免規則傳染</li>
              <li><strong>排除規則：</strong>URL Rewrite 排除 <code>^/api(/.*)?$</code>，直接交給子應用程式</li>
              <li><strong>子應用程式：</strong>在 IIS 站台下新增應用程式別名為 <code>api</code>，指向後端 publish</li>
            </ul>
          </div>
          <div className="mode-col">
            <span className="mode-tag tag-b">流派 B：Unified wwwroot (單一資料夾)</span>
            <ul>
              <li><strong>單一資料夾：</strong>後端 publish 目錄中的 <code>wwwroot</code> 放入前端 build 出來的靜態檔案</li>
              <li><strong>無須子應用程式：</strong>IIS 只需建一個站台直接指到後端目錄</li>
              <li><strong>託管方式：</strong>ASP.NET Core 直接託管 <code>UseStaticFiles()</code> 與 <code>MapFallbackToFile("index.html")</code></li>
              <li><strong>維護極簡：</strong>單一進程、單一組態、零 IIS 規則轉發衝突</li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  )
}

export default App
