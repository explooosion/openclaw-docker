# 模型設定说明

**当前設定**: Claude 3.5 Haiku  
**更新时间**: 2026-02-05

## 当前模型

```json
{
  "model": "anthropic/claude-3-5-haiku-20241022",
  "authProfiles": {
    "anthropic": {
      "apiKey": "${ANTHROPIC_API_KEY}"
    }
  }
}
```

## 可用模型

### Anthropic Claude
- `anthropic/claude-3-5-haiku-20241022` - ✅ **当前使用**（快速、经济）
- `anthropic/claude-3-5-sonnet-20241022` - 平衡性能
- `anthropic/claude-opus-4` - 最强性能

### Google Gemini
- `google/gemini-2.0-flash-exp` - 快速、免费
- `google/gemini-1.5-pro` - 高性能

### OpenAI
- `openai/gpt-4o` - 最新多模态模型
- `openai/gpt-4-turbo` - 高性能
- `openai/gpt-3.5-turbo` - 经济型

## 更换模型

### 方法 1: 修改設定文件（永久）

```bash
# 1. 編輯設定
docker exec openclaw_gateway vi /root/.openclaw/config.json

# 或从宿主机复制
cat > data/config.json << 'EOF'
{
  "gateway": {...},
  "agents": {
    "main": {
      "model": "your-model-here",
      "authProfiles": {...}
    }
  }
}
EOF

# 2. 复制到容器
docker cp data/config.json openclaw_gateway:/root/.openclaw/config.json

# 3. 重新啟動服务
docker compose restart openclaw
```

### 方法 2: 临时切换（本次会话）

在 Telegram 或 Web 界面发送：
```
/model anthropic/claude-3-5-haiku-20241022
```

## 設定文件位置

- **容器内**: `/root/.openclaw/config.json`
- **宿主机**: `./data/config.json` (持久化備份)
- **Volume 映射**: `./data:/root/.openclaw`

## API Keys 設定

在 `.env` 文件中設定对应的 API Key：

```bash
# Anthropic (Claude)
ANTHROPIC_API_KEY=sk-ant-api03-xxx

# Google (Gemini)
GEMINI_API_KEY=AIzaSyxxx

# OpenAI (GPT)
OPENAI_API_KEY=sk-xxx
```

## 验证設定

```bash
# 查看当前設定
docker exec openclaw_gateway cat /root/.openclaw/config.json

# 查看日志
docker logs openclaw_gateway 2>&1 | grep -i "model\|auth"

# 测试模型
# 在 Telegram 发送消息测试响应
```

## 模型对比

| 模型 | 速度 | 成本 | 性能 | 推荐用途 |
|------|------|------|------|---------|
| Claude 3.5 Haiku | ⚡⚡⚡ | 💰 | ⭐⭐⭐ | **日常对话、快速响应** ✅ |
| Claude 3.5 Sonnet | ⚡⚡ | 💰💰 | ⭐⭐⭐⭐ | 复杂任务、代码產生 |
| Claude Opus 4 | ⚡ | 💰💰💰 | ⭐⭐⭐⭐⭐ | 最高质量需求 |
| Gemini 2.0 Flash | ⚡⚡⚡ | 🆓 | ⭐⭐⭐ | 免费使用、快速响应 |

## 常见问题

### Q: 为什么选择 Claude Haiku？
**A**: 速度快、成本低、性能足够日常使用，适合 Telegram Bot 场景

### Q: 如何切换回 Gemini？
**A**: 修改 config.json 中的 model 为 `google/gemini-2.0-flash-exp` 并改 authProfiles

### Q: 設定是否持久化？
**A**: 是的，通过 volume 映射，設定儲存在 `./data/` 目录

### Q: 可以同时設定多个模型吗？
**A**: 可以，在 authProfiles 中設定多个 provider，使用时切换 model

## 示例：多模型設定

```json
{
  "agents": {
    "main": {
      "model": "anthropic/claude-3-5-haiku-20241022",
      "authProfiles": {
        "anthropic": {
          "apiKey": "${ANTHROPIC_API_KEY}"
        },
        "google": {
          "apiKey": "${GEMINI_API_KEY}"
        },
        "openai": {
          "apiKey": "${OPENAI_API_KEY}"
        }
      }
    }
  }
}
```

然后可以动态切换：
```
/model google/gemini-2.0-flash-exp
/model openai/gpt-4o
/model anthropic/claude-3-5-haiku-20241022
```

---

**当前状态**: ✅ 已設定 Claude 3.5 Haiku  
**API Key**: ✅ 已設定（从 .env 读取）  
**服务状态**: ✅ 运行中
