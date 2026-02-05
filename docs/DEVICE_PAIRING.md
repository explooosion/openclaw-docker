# OpenClaw 设备配对与认证指南

## 认证方式说明

OpenClaw 支持两种 Web 界面认证方式：

### 方式 1：设备配对（推荐 ✅）

**优点：**
- 更安全（每个设备独立授权）
- 支持多设备管理
- 可随时撤销单个设备权限

**流程：**
1. 浏览器访问 https://your_cloudflare_tunnels
2. 点击连接按钮，系统会发起配对请求
3. 在服务器端批准配对请求
4. 浏览器自动连接（认证信息保存在浏览器中）

**同一浏览器只需配对一次**，除非清除浏览器数据。

---

### 方式 2：Gateway Token 直接认证

**优点：**
- 简单快速
- 适合临时访问

**使用方式：**
在 Web 界面输入 Gateway Token（查看 `.env` 文件中的 `OPENCLAW_GATEWAY_TOKEN`）

> ⚠️ **注意**：如果启用了强制设备配对，此方式可能不可用

---

## 批准设备配对的方法

### 方法 1：使用便捷脚本（最简单 ⭐）

```bash
npm run devices:approve
```

或直接运行：
```bash
./scripts/approve-device.sh
```

脚本会：
- ✅ 自动显示所有待批准的设备
- ✅ 交互式确认批准操作
- ✅ 一次性批准所有待处理请求

---

### 方法 2：使用 npm 命令

**查看待批准的设备：**
```bash
npm run devices:list
```

**批准单个设备：**
```bash
docker exec openclaw_gateway openclaw devices approve <REQUEST_ID>
```

---

### 方法 3：手动命令

**列出所有配对请求：**
```bash
docker exec openclaw_gateway openclaw devices list
```

**批准指定设备：**
```bash
docker exec openclaw_gateway openclaw devices approve <DEVICE_ID>
```

**拒绝设备配对：**
```bash
docker exec openclaw_gateway openclaw devices reject <REQUEST_ID>
```

---

## 设备管理

### 查看已配对的设备

```bash
npm run devices:list
```

### 撤销设备权限

```bash
docker exec openclaw_gateway openclaw devices revoke <DEVICE_ID>
```

---

## 常见场景

### 场景 1：首次访问 Web 界面

1. 浏览器打开 https://your_cloudflare_tunnels
2. 看到配对提示
3. 在服务器运行：`npm run devices:approve`
4. 在交互提示中输入 `y` 确认
5. 浏览器刷新页面，自动连接成功 ✅

### 场景 2：更换新浏览器/设备

**方式 A：使用配对（推荐）**
1. 新浏览器访问 https://your_cloudflare_tunnels
2. 点击连接
3. 运行 `npm run devices:approve` 批准
4. 完成

**方式 B：使用 Gateway Token**
1. 新浏览器访问 https://your_cloudflare_tunnels
2. 输入 Gateway Token（查看 `.env` 文件）
3. 连接成功（如果支持）

### 场景 3：清除浏览器缓存后

与「场景 2」相同，需要重新配对或输入 Token

### 场景 4：多人共享访问

**安全方式：**
每个人独立配对，管理员批准

**简单方式：**
分享 Gateway Token（不推荐用于生产环境）

---

## 安全建议

### ✅ 推荐做法

1. **使用设备配对** - 而非直接分享 Gateway Token
2. **定期审查已配对设备** - `npm run devices:list`
3. **撤销不再使用的设备** - 及时清理
4. **修改默认 Gateway Token** - 使用强密码

### 修改 Gateway Token

编辑 `.env` 文件：
```bash
# 生成随机 Token
openssl rand -base64 32

# 更新 .env
OPENCLAW_GATEWAY_TOKEN=<新生成的token>
```

然后重启服务：
```bash
npm restart
```

---

## 自动化批准（可选）

如果你希望自动批准所有配对请求（**不推荐用于生产环境**），可以创建定时任务：

**macOS/Linux：**
```bash
# 添加到 crontab
*/5 * * * * cd /path/to/openclaw-docker && npm run devices:approve-all
```

> ⚠️ **警告**：自动批准会降低安全性，仅适用于完全可信的网络环境

---

## 故障排除

### 问题：浏览器显示 "disconnected (1008): pairing required"

**原因：** 设备配对请求未批准

**解决：**
```bash
npm run devices:approve
```

### 问题：Gateway Token 无法连接

**可能原因：**
1. Token 输入错误 - 确认 `.env` 文件中的 `OPENCLAW_GATEWAY_TOKEN` 与输入值一致
2. 启用了强制配对 - 使用设备配对方式
3. 服务未启动 - 运行 `npm run status` 检查

### 问题：配对后仍无法连接

**解决步骤：**
1. 检查浏览器控制台错误信息
2. 查看服务日志：`npm run logs`
3. 确认设备已成功配对：`npm run devices:list`
4. 清除浏览器缓存后重试

---

## 相关命令速查

| 操作 | 命令 |
|------|------|
| 查看待批准设备 | `npm run devices:list` |
| 批准设备（交互式）| `npm run devices:approve` |
| 查看服务状态 | `npm run status` |
| 查看日志 | `npm run logs` |
| 重启服务 | `npm restart` |
| 进入容器 Shell | `npm run shell` |

---

## 最佳实践总结

✅ **推荐配置（平衡安全与便利）：**
1. 个人设备使用**设备配对**
2. 配对后浏览器自动保存认证
3. 定期审查已配对设备列表
4. 临时访问可使用 Gateway Token

✅ **快速开始步骤：**
```bash
# 1. 浏览器访问
open https://your_cloudflare_tunnels

# 2. 点击连接后，批准配对
npm run devices:approve

# 3. 完成！浏览器自动连接
```

---

**更新日期：** 2026-02-06  
**OpenClaw 版本：** 2026.2.3-1
