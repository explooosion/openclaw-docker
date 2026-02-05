# 📁 OpenClaw 项目结构

## 概述

OpenClaw 是一个基于 Docker 的 AI 助手平台，支援多个 AI 提供商和多种集成渠道。

## 当前設定

**主模型**: anthropic/claude-3-haiku-20240307  
**Telegram Bot**: @your_bot_username  
**状态**: ✅ 运行中

---

## 核心文档

### 快速参考

- **[README.md](README.md)** - 项目概述
- **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** - 常用命令速查
- **[FINAL_CONFIGURATION.md](FINAL_CONFIGURATION.md)** - 完整設定文档
- **[API_AUTHENTICATION_REPORT.md](API_AUTHENTICATION_REPORT.md)** - API 认证状态

### 详细文档

完整文档位于 [docs/](docs/) 目录：

- **設定指南** ([docs/guides/](docs/guides/))
  - [TELEGRAM_SETUP.md](docs/guides/TELEGRAM_SETUP.md) - Telegram 设置
  - [MODEL_CONFIGURATION.md](docs/guides/MODEL_CONFIGURATION.md) - 模型設定
  - [MULTI_PROVIDER_SETUP.md](docs/guides/MULTI_PROVIDER_SETUP.md) - 多提供商設定
  - [SKILLS_MANAGEMENT.md](docs/guides/SKILLS_MANAGEMENT.md) - Skills 管理

- **部署指南** ([docs/deployment/](docs/deployment/))
  - [DEPLOYMENT_BEST_PRACTICES.md](docs/deployment/DEPLOYMENT_BEST_PRACTICES.md) - 最佳实践

- **架构说明** ([docs/architecture/](docs/architecture/))
  - [ARCHITECTURE.md](docs/architecture/ARCHITECTURE.md) - 系统架构
  - [FILES.md](docs/architecture/FILES.md) - 文件结构

- **故障排查** ([docs/troubleshooting/](docs/troubleshooting/))
  - [TELEGRAM_TROUBLESHOOTING.md](docs/troubleshooting/TELEGRAM_TROUBLESHOOTING.md)

---

## 项目结构

```
openclaw-workspace/
├── README.md                   # 本文件
├── docker-compose.yml          # Docker 编排設定
├── .env                        # 環境变量（密钥設定）
├── .env.example                # 環境变量示例
├── start-openclaw.sh           # 啟動脚本
│
├── data/                       # OpenClaw 資料目录
│   ├── openclaw.json           # 主設定文件
│   ├── openclaw.json.example   # 設定示例
│   ├── workspace/              # 工作区
│   │   ├── IDENTITY.md         # AI 身份設定
│   │   ├── SOUL.md             # AI 个性設定
│   │   ├── USER.md             # 用户信息（需手动設定）
│   │   ├── TOOLS.md            # 工具設定
│   │   └── skills/             # Skills 目录
│   ├── agents/                 # Agent 設定
│   │   └── main/agent/
│   │       ├── auth-profiles.json  # API 认证
│   │       └── models.json         # 模型註冊
│   └── cron/                   # 定时任务
│
├── docs/                       # 文档目录
│   ├── README.md               # 文档索引
│   ├── guides/                 # 設定指南
│   ├── deployment/             # 部署指南
│   ├── architecture/           # 架构文档
│   ├── troubleshooting/        # 故障排查
│   └── archive/                # 历史文档（已归档）
│
├── skills-custom/              # 自定义 Skills（用户特定）
│   ├── README.md
│   └── .gitkeep
│
├── gog-config/                 # Google Workspace 設定
└── certs/                      # TLS 证书
```

---

## 設定文件说明

### 環境設定

| 文件 | 用途 | 是否提交到 Git |
|------|------|----------------|
| `.env` | 实际密钥和設定 | ❌ No (gitignore) |
| `.env.example` | 設定模板和说明 | ✅ Yes |

### OpenClaw 設定

| 文件 | 用途 | 是否提交到 Git |
|------|------|----------------|
| `data/openclaw.json` | 实际設定 | ❌ No (gitignore) |
| `data/openclaw.json.example` | 設定示例 | ✅ Yes |

### 认证設定

| 文件 | 用途 | 是否提交到 Git |
|------|------|----------------|
| `data/agents/main/agent/auth-profiles.json` | API 密钥 | ❌ No (gitignore) |
| `data/agents/main/agent/models.json` | 模型註冊 | ❌ No (gitignore) |

### 用户特定文件

| 文件 | 用途 | 是否提交到 Git |
|------|------|----------------|
| `data/workspace/USER.md` | 用户信息 | ❌ No (gitignore) |
| `data/workspace/HEARTBEAT.md` | 运行状态 | ❌ No (gitignore) |
| `data/workspace/BOOTSTRAP.md` | 初始化记录 | ❌ No (gitignore) |
| `skills-custom/` | 自定义 Skills | ❌ No (gitignore) |
| `gog-config/` | Google Workspace | ❌ No (gitignore) |

---

## 快速开始

### 1. 設定環境变量

```bash
cp .env.example .env
nano .env  # 填入 API 密钥
```

### 2. 設定 OpenClaw

```bash
cp data/openclaw.json.example data/openclaw.json
nano data/openclaw.json  # 根据需要调整
```

### 3. 啟動服务

```bash
docker compose up -d
```

### 4. 查看日志

```bash
docker logs -f openclaw_gateway
```

---

## 常用命令

```bash
# 啟動
docker compose up -d

# 重新啟動
docker compose restart openclaw

# 查看日志
docker logs -f openclaw_gateway

# 停止
docker compose down

# 查看状态
docker ps

# 进入容器
docker exec -it openclaw_gateway bash
```

---

## AI 提供商

### 已設定

- **Anthropic Claude** ✅ (主模型)
  - claude-3-haiku-20240307
  - claude-3-5-sonnet-20241022
  
- **Google Gemini** ✅ (备用)
  - gemini-2.0-flash-exp
  - gemini-1.5-pro

- **OpenAI** ⚠️ (认证有效但模型註冊问题)
  - gpt-3.5-turbo (暂不可用)
  - gpt-4o

### 未設定

- Notion Integration
- Slack Bot

---

## 集成渠道

### 已設定

- **Telegram** ✅
  - Bot: @your_bot_username
  - 白名单模式

### 未設定

- Slack
- Discord
- Matrix

---

## Skills

### 内置 Skills

位于 `data/workspace/skills/bundled/`:
- GitHub 集成
- Google Workspace
- 天气查詢
- 等...

### 自定义 Skills

位于 `skills-custom/`:
- QR Code Generator
- 天气查詢 (自定义版本)

---

## 支援

- **文档**: [docs/README.md](docs/README.md)
- **快速参考**: [QUICK_REFERENCE.md](QUICK_REFERENCE.md)
- **設定详情**: [FINAL_CONFIGURATION.md](FINAL_CONFIGURATION.md)
- **API 状态**: [API_AUTHENTICATION_REPORT.md](API_AUTHENTICATION_REPORT.md)

---

**最后更新**: 2026-02-05  
**OpenClaw 版本**: 2026.2.3-1  
**状态**: ✅ 正常运行
