# OpenClaw Docker Workspace

使用 Docker Compose 部署 OpenClaw Gateway + Traefik 反向代理的完整解決方案。

**OpenClaw** 是一個統一的 AI 助手平台，可連接多個通訊渠道（WhatsApp、iMessage、Telegram 等），並透過 50+ Skills 擴展能力。

## 🎯 核心價值

OpenClaw 不只是聊天工具，而是：

- 🌐 **多通道 AI 助手** - 在任何平台使用同一個 AI
- 🧩 **Skills 生態系統** - 50+ 工具整合（GitHub、筆記本本、智慧家居等）
- 🤖 **自動化引擎** - 複雜工作流自動執行
- 🔄 **靈活 AI 引擎** - 支援 Claude、Gemini 等多種 AI

📚 **詳細說明**：[OpenClaw 核心價值與使用指南](./docs/OPENCLAW_VALUE_PROPOSITION.md)

## 快速開始

```bash
# 1. 克隆倉庫
git clone <YOUR_REPO_URL> openclaw-workspace
cd openclaw-workspace

# 2. 產生 TLS 證書
mkdir -p certs
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout certs/local-key.pem \
  -out certs/local-cert.pem \
  -subj "/C=TW/ST=Taiwan/L=Taipei/O=Local/OU=Dev/CN=openclaw.local"
chmod 600 certs/local-key.pem

# 3. 設定環境變數
cp .env.example .env
nano .env  # 修改 OPENCLAW_GATEWAY_TOKEN 和 API Keys

# 4. 設定本地網域名稱
echo "127.0.0.1 openclaw.local" | sudo tee -a /etc/hosts
echo "127.0.0.1 gemini.local" | sudo tee -a /etc/hosts

# 5. 啟動服務
docker compose up -d

# 6. 存取服務
# OpenClaw Web Chat: https://openclaw.local/
# Gemini Web Chat: https://gemini.local/
```

## 文檔

### 核心文檔
- **[OpenClaw 核心價值](./docs/OPENCLAW_VALUE_PROPOSITION.md)** ⭐ 必讀！了解 OpenClaw 的真正意義
- **[系統架構文檔](./docs/ARCHITECTURE.md)** - 深入了解系統設計、組件和網路流程
- **[完整部署指南](./docs/SETUP.md)** - 詳細的安裝步驟、設定說明和故障排除

### AI 整合指南
- **[Gemini 設定指南](./docs/GEMINI_SETUP.md)** - Google Gemini CLI 安裝與設定
- **[Gemini Web Chat](./docs/GEMINI_WEB_CHAT.md)** - 獨立 Web 界面使用說明
- **[Chat 功能對比](./docs/CHAT_WITH_GEMINI.md)** - OpenClaw vs Gemini Web 比較

## 主要特性

### 平台整合
- ✅ **多通道支援**: WhatsApp、iMessage、Telegram、Slack、Email 等
- ✅ **統一 AI 助手**: 在任何平台使用同一個智慧助手
- ✅ **Skills 系統**: 50+ 可擴展技能（已整合 6 個核心 Skills）

### 已整合 Skills（開箱即用）
- ✅ **Gemini** (♊️) - Google AI 問答、總結、產生
- ✅ **GitHub** (🐙) - GitHub 整合（需設定 token）
- ✅ **Weather** (🌤️) - 天氣查詢（無需 API key）
- ✅ **gog** (🎮) - Google Workspace（Calendar、Gmail、Drive）
- ✅ **Healthcheck** (📦) - 系統安全檢查
- ✅ **Skill Creator** (📦) - 建立自定義 Skills
- ✅ **BlueBubbles** (📦) - iMessage 整合插件

### 📱 Telegram Bot 整合（推薦使用）

**主要互動介面** - 透過 Telegram 使用 OpenClaw AI 助理：

```bash
# 1. 在 Telegram 與 @BotFather 對話建立 Bot
# 2. 獲取 Token 並加入 .env
echo "TELEGRAM_BOT_TOKEN=你的Bot Token" >> .env

# 3. 啟動 Telegram Bot
docker compose up -d telegram-bot

# 4. 在 Telegram 搜尋你的 Bot 並開始對話！
```

**功能特色：**
- ✅ 自然語言互動（無需特殊格式）
- ✅ 行事曆管理、天氣查詢、待辦事項
- ✅ 支援所有已設定的 Skills
- ✅ 獨立 Session 管理（每用戶獨立對話歷史）
- ✅ 指令系統（/start, /help, /status, /clear）

📚 **完整教學**：[Telegram Bot 設定指南](./docs/TELEGRAM_SETUP.md)

### 🎁 擴充 Skills（一鍵安裝）

想要更多功能？從 [awesome-openclaw-skills](https://github.com/VoltAgent/awesome-openclaw-skills) 安裝：

```bash
# 安裝 Home Assistant Skill
./scripts/install-skill.sh home-assistant https://github.com/VoltAgent/skill-home-assistant.git

# 安裝 Spotify Skill
./scripts/install-skill.sh spotify https://github.com/VoltAgent/skill-spotify.git

# 更新所有 Skills
./scripts/update-skills.sh
```

📚 **詳細說明**：
- [Skills 管理指南](./docs/SKILLS_MANAGEMENT.md) - Skills 安裝、更新和設定
- [Skills 整合報告](./docs/SKILLS_INTEGRATION_REPORT.md) - 已整合 Skills 詳情

### AI 能力
- ✅ **雙 AI 引擎**: Anthropic Claude + Google Gemini
- ✅ **Gemini CLI**: 免費的命令行 AI 工具（已預裝）
- ✅ **Gemini Web Chat**: 自定義 Web 界面（已部署）

### 技術特性
- ✅ **反向代理**: 使用 Traefik v3.0 自動路由和 TLS 終止
- ✅ **HTTPS 支援**: 本地自簽名證書（可替換為 Let's Encrypt）
- ✅ **資料持久化**: Volume mount 儲存設定和會話
- ✅ **裝置配對**: 內建安全機制保護 Gateway 存取
- ✅ **Docker 網路**: 隔離的橋接網路確保服務間通信
- ✅ **預裝工具**: curl, wget, jq, git, gh (GitHub CLI), python3

## 架構概覽

```
Browser (HTTPS) → Traefik (Port 443) → Socat (Port 18790) → OpenClaw Gateway (Port 18789)
```

## 常用命令

```bash
# 啟動服務
docker compose up -d

# 停止服務
docker compose down

# 查看日誌
docker compose logs -f openclaw

# 重啟 OpenClaw
docker compose restart openclaw

# 查看容器狀態

# 安裝新 Skill（一鍵）
./scripts/install-skill.sh calendar https://github.com/VoltAgent/skill-calendar.git

# 更新所有 Skills
./scripts/update-skills.sh

# 查看容器狀態
docker compose ps

# 批準裝置配對
docker exec openclaw_gateway openclaw devices list
docker exec openclaw_gateway openclaw devices approve <REQUEST_ID>

# 檢查 Gateway 狀態
docker exec openclaw_gateway openclaw gateway status

# 使用 Gemini AI（需設定 GEMINI_API_KEY）
docker exec openclaw_gateway gemini "你好，請介紹一下 Docker"

# 查看可用 Skills
docker exec openclaw_gateway openclaw skills list
```

## Gemini AI 快速設定

```bash
# 1. 獲取 API Key: https://aistudio.google.com/api-keys

# 2. 添加到 .env
echo "GEMINI_API_KEY=your_api_key_here" >> .env

# 3. 重新啟動容器
docker compose restart openclaw

# 4. 測試 Gemini
sleep 90  # 等待啟動
docker exec openclaw_gateway gemini "你好"
```

詳細設定請參考 [GEMINI_SETUP.md](./docs/GEMINI_SETUP.md)。

## 連接埠說明

| 連接埠 | 服務 | 用途 |
|------|------|------|
| 80 | Traefik | HTTP 入口（可重新導向至 HTTPS） |
| 443 | Traefik | HTTPS 入口（主要存取連接埠） |
| 8080 | Traefik | Dashboard（監控和除錯） |

## 環境變數

| 變數 | 必需 | 說明 |
|------|------|------|
| `OPENCLAW_GATEWAY_TOKEN` | ✅ | Gateway 認證 Token |
| `GEMINI_API_KEY` | ❌ | Google Gemini API Key（啟用 AI 功能） |
| `TZ` | ❌ | 時區設定（預設 Asia/Taipei） |
| `OPENCLAW_GATEWAY_PORT` | ❌ | Gateway 連接埠（預設 18789） |
| `CF_TUNNEL_TOKEN` | ❌ | Cloudflare Tunnel Token（公網存取） |

## 安全提示

- **修改預設 Token**: 務必在 `.env` 中修改 `OPENCLAW_GATEWAY_TOKEN`
- **私鑰權限**: 確保 `certs/local-key.pem` 權限為 600
- **裝置配對**: 首次連線需要手動批准（安全機制）
- **正式環境**: 使用有效 TLS 憑證替換自簽名憑證

## 故障排除

### 無法存取 https://openclaw.local/

```bash
# 檢查容器狀態
docker compose ps

# 查看 Traefik 日誌
docker logs traefik --tail 50

# 確認網域名稱解析
ping openclaw.local
```

### 裝置配對失敗

```bash
# 查看待配對裝置
docker exec openclaw_gateway openclaw devices list

# 批准配對
docker exec openclaw_gateway openclaw devices approve <REQUEST_ID>
```

更多故障排除方法請參考 [SETUP.md](./docs/SETUP.md#常見問題排查)。

## 許可證

[指定你的許可證]

## 貢獻

歡迎提交 Issue 和 Pull Request！

## 相關資源

- [OpenClaw 官方文檔](https://docs.openclaw.ai/)
- [Traefik 文檔](https://doc.traefik.io/traefik/)
- [Google AI Studio](https://aistudio.google.com/) - 獲取 Gemini API Key
- [ClawHub](https://clawhub.com/) - OpenClaw Skills 市場

## 完整文檔

- 📖 [系統架構](./docs/ARCHITECTURE.md) - 詳細技術架構和組件說明
- 🚀 [部署指南](./docs/SETUP.md) - 完整安裝步驟和設定指南
- ⚡ [快速參考](./docs/QUICK_REFERENCE.md) - 常用命令速查
- 🤖 [Gemini AI 設定](./docs/GEMINI_SETUP.md) - Gemini 詳細設定和使用
- 📁 [文件清單](./docs/FILES.md) - 項目文件說明
- 🤝 [貢獻指南](./docs/CONTRIBUTING.md) - 如何參與項目
- 📋 [發布檢查清單](./docs/PUBLISH_CHECKLIST.md) - GitHub 發布準備
- [Docker Compose 文檔](https://docs.docker.com/compose/)
