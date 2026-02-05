# OpenClaw Custom Skills

此目录用于存放自定义的 OpenClaw Skills。

## 📁 目录结构

```
skills-custom/
├── README.md           # 说明文档
├── weather/            # 天气查詢 Skill
│   ├── SKILL.md
│   ├── config.json
│   └── weather.sh
└── qrcode/             # 二维码產生 Skill
    ├── SKILL.md
    ├── config.json
    └── qrcode.sh
```

## 🔄 持久化机制

### Docker Volume 映射

在 `docker-compose.yml` 中設定：

```yaml
volumes:
  - ./skills-custom:/root/.openclaw/skills/custom:ro
```

这样确保：
- ✅ 服务重新啟動后 Skills 設定保留
- ✅ 宿主机可直接編輯 Skills
- ✅ 版本控制（Git）跟踪变更

### 验证持久化

```bash
# 1. 查看当前 Skills
docker exec openclaw_gateway openclaw skills list

# 2. 重新啟動容器
docker compose restart gateway

# 3. 再次查看（应该仍然存在）
docker exec openclaw_gateway openclaw skills list

# 4. 使用验证脚本
./scripts/verify-skills-persistence.sh
```

## 🎯 已包含的 Skills

### 1. Weather Skill (天气查詢)

**功能**: 使用 OpenWeatherMap API 查詢天气

**設定**: 需要在 `.env` 添加
```bash
OPENWEATHER_API_KEY=your_key_here
```

**获取 API Key**: https://openweathermap.org/api (免费层：60次/分钟)

**测试**:
```bash
./scripts/test-skill.sh weather
```

**使用**:
- Telegram: "台北今天天气如何？"
- 命令行: `docker exec openclaw_gateway openclaw skills run weather taipei`

---

### 2. QR Code Skill (二维码產生)

**功能**: 產生二维码图片

**依赖**: 需要在容器中安装 `qrencode`

**安装依赖**:
```bash
# 进入容器
docker exec -it openclaw_gateway bash

# 安装 qrencode
apt-get update && apt-get install -y qrencode

# 或者在 Dockerfile 中添加
```

**测试**:
```bash
./scripts/test-skill.sh qrcode
```

**使用**:
- Telegram: "產生二维码：https://example.com"
- 命令行: `docker exec openclaw_gateway openclaw skills run qrcode "Hello"`

## ➕ 添加新 Skill

### 方法 1: 手动建立

```bash
# 1. 建立目录
mkdir -p skills-custom/myskill

# 2. 建立必要文件
cat > skills-custom/myskill/SKILL.md << 'EOF'
# My Skill
Description...
EOF

cat > skills-custom/myskill/config.json << 'EOF'
{
  "name": "myskill",
  "version": "1.0.0",
  "description": "My custom skill"
}
EOF

# 3. 建立执行脚本
cat > skills-custom/myskill/myskill.sh << 'EOF'
#!/bin/bash
echo "Hello from my skill!"
EOF

chmod +x skills-custom/myskill/myskill.sh

# 4. 重新啟動容器
docker compose restart gateway

# 5. 验证
docker exec openclaw_gateway openclaw skills list | grep myskill
```

### 方法 2: 使用安装脚本

```bash
./scripts/install-skill.sh myskill
```

## 📋 Skill 规范

每个 Skill 目录应包含：

### 必需文件

1. **SKILL.md** - Skill 说明文档
   ```markdown
   # Skill Name
   Description
   
   ## 功能
   ## 設定
   ## 使用示例
   ## 依赖
   ```

2. **config.json** - Skill 設定
   ```json
   {
     "name": "skill-name",
     "version": "1.0.0",
     "description": "...",
     "requirements": {
       "binaries": ["curl"],
       "env": ["API_KEY"]
     },
     "commands": {...},
     "triggers": {...}
   }
   ```

3. **可执行脚本** - 实际功能实现
   - Shell: `skill-name.sh`
   - Python: `skill-name.py`
   - Node.js: `skill-name.js`

### 可选文件

- `README.md` - 详细文档
- `test.sh` - 测试脚本
- `.env.example` - 環境变量示例
- `install.sh` - 依赖安装脚本

## 🔍 调试 Skills

### 查看 Skills 状态

```bash
# 列出所有 Skills
docker exec openclaw_gateway openclaw skills list

# 查看特定 Skill
docker exec openclaw_gateway openclaw skills info weather

# 查看容器内的 Skills 目录
docker exec openclaw_gateway ls -la /root/.openclaw/skills/custom/
```

### 测试 Skill 功能

```bash
# 使用测试工具
./scripts/test-skill.sh weather

# 直接运行
docker exec openclaw_gateway bash /root/.openclaw/skills/custom/weather/weather.sh taipei

# 查看日志
docker logs openclaw_gateway --tail 50 | grep -i skill
```

### 常见问题

**Q: 重新啟動后 Skill 消失？**
```bash
# 检查 volume 映射
docker inspect openclaw_gateway | grep -A 5 Mounts

# 检查宿主机文件
ls -la /Users/robby/Desktop/docker/openclaw-workspace/skills-custom/

# 检查容器内文件
docker exec openclaw_gateway ls -la /root/.openclaw/skills/custom/
```

**Q: Skill 无法执行？**
```bash
# 检查权限
ls -l skills-custom/weather/weather.sh

# 添加执行权限
chmod +x skills-custom/weather/*.sh

# 检查依赖
docker exec openclaw_gateway which curl python3
```

**Q: Skill 未被识别？**
```bash
# 重新啟動容器
docker compose restart gateway

# 强制重新加载
docker exec openclaw_gateway openclaw skills reload

# 查看設定文件
docker exec openclaw_gateway cat /root/.openclaw/skills/custom/weather/config.json
```

## 📚 参考资源

### 官方文档
- ClawHub: https://clawhub.ai/
- OpenClaw Skills: 内建文档

### 示例 Skills
- [Awesome OpenClaw Skills](https://github.com/topics/openclaw-skill)
- ClawHub Skills Market

### 本地文档
- [Skills 管理指南](../docs/guides/SKILLS_MANAGEMENT.md)
- [Skills 测试报告](../docs/testing/SKILLS_TEST_REPORT.md)
- [测试工具](../scripts/test-skill.sh)

## 🛠️ 管理工具

### 测试工具
```bash
./scripts/test-skill.sh weather
./scripts/test-skill.sh -v qrcode
./scripts/test-skill.sh --list
```

### 验证持久化
```bash
./scripts/verify-skills-persistence.sh
```

### 安装新 Skill
```bash
./scripts/install-skill.sh skill-name [git-url]
```

## 📝 版本控制

此目录通过 Git 管理：

```bash
# 添加新 Skill
git add skills-custom/myskill/
git commit -m "Add myskill"

# 更新 Skill
git add skills-custom/weather/
git commit -m "Update weather skill config"

# 查看历史
git log -- skills-custom/
```

## 🚀 快速开始

```bash
# 1. 检查当前 Skills
docker exec openclaw_gateway openclaw skills list

# 2. 設定 API Keys（如需要）
echo "OPENWEATHER_API_KEY=your_key" >> .env

# 3. 重新啟動容器
docker compose restart gateway

# 4. 验证 Skills
./scripts/test-skill.sh weather
./scripts/test-skill.sh qrcode

# 5. 在 Telegram 测试
# 发送: "台北今天天气如何？"
```

---

**最后更新**: 2026-02-05  
**Skills 数量**: 2 个 (weather, qrcode)  
**状态**: ✅ 持久化已設定
