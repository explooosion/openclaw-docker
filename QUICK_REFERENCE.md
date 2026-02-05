# OpenClaw 快速参考

## 🚀 快速啟動

```bash
cd /Users/robby/Desktop/docker/openclaw-workspace
docker compose up -d
```

## 📊 系统状态

**当前模型**: `anthropic/claude-3-haiku-20240307`  
**Telegram Bot**: @your_bot_username  
**授权用户**: YOUR_USER_ID  
**状态**: ✅ 运行中

## 🔧 常用命令

### Docker 管理

```bash
# 啟動
docker compose up -d

# 停止
docker compose down

# 重新啟動
docker compose restart openclaw

# 查看日志
docker logs -f openclaw_gateway

# 检查状态
docker ps --filter name=openclaw_gateway
```

### 設定管理

```bash
# 編輯主設定
nano data/openclaw.json

# 查看当前模型
docker logs openclaw_gateway 2>&1 | grep "agent model"

# 验证 Telegram 連線
docker logs openclaw_gateway 2>&1 | grep telegram | tail -5
```

### 故障排查

```bash
# 查看错误日志
docker logs openclaw_gateway 2>&1 | grep -i error | tail -20

# 验证认证設定
docker exec openclaw_gateway cat /root/.openclaw/agents/main/agent/auth-profiles.json

# 重置服务
docker compose down && docker compose up -d
```

## 💬 Telegram 命令

- `/model` - 查看/切换模型
- `/model status` - 模型详细状态
- `@your_bot_username <消息>` - 在群组中提及使用

## 📁 重要文件

```
data/openclaw.json                    # 主設定
data/agents/main/agent/auth-profiles.json  # 认证
data/agents/main/agent/models.json         # 模型註冊
docker-compose.yml                    # Docker 設定
```

## 🔐 安全信息

- **白名单**: 設定於 telegram-allowFrom.json
- **网关**: 仅本地存取 (127.0.0.1:18789)
- **群组**: 需要 @提及

## 💰 成本参考

| 模型 | 输入成本 | 输出成本 | 状态 |
|------|---------|---------|------|
| Claude 3 Haiku | $0.25/1M | $1.25/1M | ✅ 主模型 |
| Gemini Flash | 免费层级 | 免费层级 | ✅ 备用 |
| GPT-3.5 Turbo | $0.50/1M | $1.50/1M | ⚠️ 暂不可用 |

## 🆘 紧急处理

### Bot 无响应
```bash
docker compose restart openclaw
sleep 60
docker logs openclaw_gateway --tail 20
```

### 設定错误
```bash
# 復原設定
cp data/openclaw.json.backup data/openclaw.json
docker compose restart openclaw
```

### 完全重置
```bash
docker compose down
docker compose up -d
# 等待 90 秒啟動完成
sleep 90
docker logs openclaw_gateway --tail 30
```

## 📞 联系信息

**文档**: `./FINAL_CONFIGURATION.md`  
**設定审計**: `./CONFIGURATION_AUDIT.md`  
**驗證報告**: `./VERIFICATION_REPORT.md`

---

**最后更新**: 2026-02-05 20:45 CST
