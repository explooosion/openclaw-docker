# 多模型提供商設定指南

## 理念

OpenClaw 支援**多个 AI 模型提供商**，通过設定文件统一管理，无需在容器内安装特定的 CLI 工具。

### 支援的提供商

| 提供商 | 模型示例 | API Key 環境变量 | 成本 |
|--------|---------|-----------------|------|
| **Anthropic** | Claude 3.5 Haiku, Sonnet, Opus 4.5 | `ANTHROPIC_API_KEY` | 💰💰 |
| **Google** | Gemini 2.0 Flash, Gemini 1.5 Pro | `GEMINI_API_KEY` | 🆓 免费层 |
| **OpenAI** | GPT-4o, GPT-4 Turbo, GPT-3.5 | `OPENAI_API_KEY` | 💰💰💰 |

## 設定方式

### 1. 添加 API Keys（.env 文件）

```bash
# Anthropic Claude
ANTHROPIC_API_KEY=sk-ant-api03-xxxxx

# Google Gemini
GEMINI_API_KEY=AIzaSyxxxxx

# OpenAI GPT
OPENAI_API_KEY=sk-xxxxx
```

### 2. 选择預設模型（data/config.json）

```json
{
  "agents": {
    "main": {
      "model": "anthropic/claude-3-5-haiku-20241022",
      "authProfiles": {
        "anthropic": {
          "apiKey": "${ANTHROPIC_API_KEY}"
        }
      }
    }
  }
}
```

### 3. 可用模型列表

#### Anthropic Claude
```
anthropic/claude-3-5-haiku-20241022     # 快速、经济 ✅ 推荐日常使用
anthropic/claude-3-5-sonnet-20241022    # 平衡性能
anthropic/claude-opus-4-5               # 最强性能
```

#### Google Gemini
```
google/gemini-2.0-flash-exp             # 快速、免费 ✅ 推荐测试
google/gemini-1.5-pro                   # 高性能
google/gemini-1.5-flash                 # 快速响应
```

#### OpenAI GPT
```
openai/gpt-4o                           # 最新多模态
openai/gpt-4-turbo                      # 高性能
openai/gpt-3.5-turbo                    # 经济型
```

## 切换模型

### 方法 1: 修改設定文件（永久）

編輯 `data/config.json`：
```json
{
  "agents": {
    "main": {
      "model": "google/gemini-2.0-flash-exp",
      "authProfiles": {
        "google": {
          "apiKey": "${GEMINI_API_KEY}"
        }
      }
    }
  }
}
```

应用設定：
```bash
docker cp data/config.json openclaw_gateway:/root/.openclaw/config.json
docker compose restart openclaw
```

### 方法 2: 运行时切换（临时）

在 Telegram 或 Web 界面：
```
/model anthropic/claude-3-5-haiku-20241022
/model google/gemini-2.0-flash-exp
/model openai/gpt-4o
```

## 多提供商設定示例

同时設定所有提供商，可以随时切换：

**data/config.json:**
```json
{
  "gateway": {
    "mode": "local",
    "bind": "loopback",
    "trustedProxies": ["127.0.0.1", "0.0.0.0/0", "::/0"]
  },
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

**.env:**
```bash
ANTHROPIC_API_KEY=sk-ant-api03-xxxxx
GEMINI_API_KEY=AIzaSyxxxxx
OPENAI_API_KEY=sk-xxxxx
```

## 优势

### ✅ 灵活性
- 无需重新构建容器
- 运行时动态切换模型
- 支援多个提供商并存

### ✅ 可维护性
- 設定集中管理
- 環境变量安全存储
- 版本控制友好

### ✅ 成本优化
- 免费层测试（Gemini）
- 按需切换到付费模型
- 根据任务选择合适的模型

## 推荐設定策略

### 场景 1: 开发测试
```json
"model": "google/gemini-2.0-flash-exp"
```
- 免费使用
- 快速响应
- 适合调试

### 场景 2: 日常使用
```json
"model": "anthropic/claude-3-5-haiku-20241022"
```
- 速度快
- 成本低
- 性能够用

### 场景 3: 复杂任务
```json
"model": "anthropic/claude-opus-4-5"
```
- 最强性能
- 深度思考
- 高质量输出

### 场景 4: 多模态需求
```json
"model": "openai/gpt-4o"
```
- 图像理解
- 视觉任务
- 多模态处理

## 验证設定

```bash
# 1. 检查容器内設定
docker exec openclaw_gateway cat /root/.openclaw/config.json

# 2. 查看认证設定
docker exec openclaw_gateway cat /root/.openclaw/agents/main/agent/auth-profiles.json

# 3. 查看啟動日志中的模型
docker logs openclaw_gateway 2>&1 | grep "agent model"

# 4. 使用验证脚本
./scripts/verify-model.sh
```

## 故障排除

### 问题: API Key 未生效
```bash
# 检查環境变量
docker exec openclaw_gateway env | grep -E "ANTHROPIC|GEMINI|OPENAI"

# 重新加载設定
docker compose restart openclaw
```

### 问题: 模型切换失败
```bash
# 检查模型名称是否正确
cat data/config.json | jq .agents.main.model

# 确保对应的 API Key 已設定
cat .env | grep -E "ANTHROPIC|GEMINI|OPENAI"
```

### 问题: 认证失败
```bash
# 验证 API Key 格式
# Anthropic: sk-ant-api03-xxxxx
# Gemini: AIzaSyxxxxx
# OpenAI: sk-xxxxx

# 重新設定
vim .env
docker compose restart openclaw
```

## 最佳实践

1. **始终設定备用提供商** - 避免单点故障
2. **使用免费层测试** - Gemini 作为开发测试環境
3. **根据任务选择** - 简单任务用 Haiku，复杂任务用 Opus
4. **定期更新模型** - 关注最新的模型版本
5. **监控成本** - 跟踪 API 使用量

## 参考资源

- [Anthropic API 文档](https://docs.anthropic.com/)
- [Google AI Studio](https://aistudio.google.com/)
- [OpenAI API 文档](https://platform.openai.com/docs)
- [模型設定文档](MODEL_CONFIGURATION.md)

---

**設定理念**: 通过外部設定管理多个"大脑"，灵活切换，而不是在容器内硬编码特定工具。
