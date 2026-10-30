var builder = WebApplication.CreateBuilder(args);

// Add services
builder.Services.AddEndpointsApiExplorer();

var app = builder.Build();

// 支援流派 B (Unified Wwwroot)：託管靜態檔案與 SPA 前端
app.UseDefaultFiles();
app.UseStaticFiles();

// 測試 API 端點
// 同時註冊 "/api/hello" 與 "/hello"：
// - 流派 B (Unified)：以根目錄站台執行，前端請求為 /api/hello，命中 /api/hello
// - 流派 A (Sub-App)：掛載於 IIS /api 子應用程式，IIS 會將 PathBase 設為 /api，請求路徑變為 /hello，命中 /hello
var helloHandler = () => Results.Ok(new
{
    message = "成功從單一 IIS 站台呼叫後端 C# API！",
    serverTime = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss"),
    machineName = Environment.MachineName
});

app.MapGet("/api/hello", helloHandler);
app.MapGet("/hello", helloHandler);

// 支援流派 B SPA 路由 Fallback (非 API 請求且非實體檔案時回傳 index.html)
app.MapFallbackToFile("index.html");

app.Run();
