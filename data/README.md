# OpenClaw 資料目錄設定指南

此目錄包含 OpenClaw 的設定檔案和執行時資料。許多檔案被排除於 git 之外,因為它們包含敏感資訊或環境特定資料。

## 🔧 初始設定（新環境）

在新機器或環境中設定時：

### 1. 複製範例檔案

```bash
# 核心設定
cp data/config.json.example data/config.json
cp data/credentials.json.example data/credentials.json
cp data/openclaw.json.example data/openclaw.json

# Agent 設定
cp data/agents/main/agent/auth-profiles.json.example data/agents/main/agent/auth-profiles.json

# Cron 任務
cp data/cron/jobs.json.example data/cron/jobs.json
```

### 2. 設定 API 金鑰

編輯 [data/credentials.json](credentials.json)：
- 新增您的 Google OAuth 用戶端憑證
- 參考 [credentials.json.example](credentials.json.example) 瞭解結構

編輯 [data/agents/main/agent/auth-profiles.json](agents/main/agent/auth-profiles.json)：
- 新增您的 Anthropic API 金鑰
- 新增您的 Google/Gemini API 金鑰
- 參考 [auth-profiles.json.example](auth-profiles.json.example) 瞭解結構

或在 `.env` 中使用環境變數：
```bash
GEMINI_API_KEY=your_key_here
ANTHROPIC_API_KEY=your_key_here
GITHUB_TOKEN=your_token_here
GOG_KEYRING_PASSWORD=your_password_here
GOG_ACCOUNT=your_email@gmail.com
```

### 3. 目錄結構

以下目錄將在執行時自動建立：
- `devices/` - 裝置配對資料（本機狀態）
- `identity/` - 裝置身份和驗證
- `agents/main/sessions/` - Agent 對話工作階段（類似資料庫）

## 📁 檔案分類

### ✅ Git 追蹤（範本）
- `*.example` 檔案 - 設定範本
- `canvas/index.html` - Web 介面
- `workspace/*.md` - 系統文件

### ❌ Git 排除（本機/敏感）

**敏感憑證：**
- `credentials.json` - Google OAuth 憑證
- `agents/*/agent/auth-profiles.json` - API 金鑰
- `identity/` - 裝置驗證權杖

**使用者特定設定：**
- `config.json` - 本機 OpenClaw 設定
- `openclaw.json` - 執行時設定
- `agents/*/agent/USER.md` - Agent 的使用者資料

**執行時資料：**
- `agents/*/sessions/` - 對話歷史記錄（資料庫）
- `devices/` - 裝置配對狀態
- `update-check.json` - 更新檢查快取
- `cron/jobs.json` - 排程任務

**備份檔案：**
- `*.bak`, `*.bak.*` - 自動產生的備份

## 🔐 Google Workspace（gog CLI）設定

1. 在 `credentials.json` 中設定 OAuth 憑證
2. 在 `.env` 中設定環境變數：
   ```bash
   GOG_KEYRING_PASSWORD=your_secure_password
   GOG_ACCOUNT=your_email@gmail.com
   ```
3. 執行授權：
   ```bash
   docker exec openclaw_gateway gog auth add your_email@gmail.com --services calendar
   ```

gog 設定儲存在 `../gog-config/`（同樣排除於 git 之外）。

## 📝 注意事項

- 切勿將真實的 API 金鑰或憑證提交到 git
- `.gitignore` 檔案會自動保護敏感資料
- 範例檔案為新環境提供結構
- 工作階段資料被視為資料庫（僅限本機）
- 裝置配對和身份資訊為機器特定

## 🆘 故障排除

**「遺失設定檔案」**
→ 從 `.example` 檔案複製並填入您的值

**「無效憑證」**
→ 檢查 `credentials.json` 和 `auth-profiles.json` 是否有有效的 API 金鑰

**「工作階段未持久化」**
→ 正常 - 工作階段是本機的，按設計排除於 git 之外
