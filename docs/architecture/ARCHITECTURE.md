# OpenClaw + Traefik Docker 架構文檔

## 架構概覽

本項目實現了基於 Docker 的 OpenClaw Gateway 部署方案，使用 Traefik 作為反向代理，支援本地 HTTPS 存取。

### 系統架構圖

```
┌─────────────────────────────────────────────────────────────────┐
│                         外部存取層                                │
│                                                                 │
│  瀏覽器 (https://openclaw.local/)                                │
│      │                                                          │
│      │ HTTPS (443)                                             │
│      ▼                                                          │
└─────────────────────────────────────────────────────────────────┘
                               │
┌──────────────────────────────┼──────────────────────────────────┐
│                              │   Docker 網路層 (openclaw_net)    │
│                              ▼                                   │
│  ┌────────────────────────────────────────────────┐             │
│  │          Traefik 反向代理                        │             │
│  │  - 連接埠: 80, 443, 8080                          │             │
│  │  - TLS 終止: local-cert.pem                     │             │
│  │  - 路由規則: Host(`openclaw.local`)              │             │
│  └─────────────────┬──────────────────────────────┘             │
│                    │ HTTP (port 18790)                          │
│                    ▼                                            │
│  ┌────────────────────────────────────────────────┐             │
│  │    OpenClaw Gateway 容器                        │             │
│  │  ┌──────────────────────────────────────────┐  │             │
│  │  │  Socat TCP 代理                          │  │             │
│  │  │  監聽: 0.0.0.0:18790                     │  │             │
│  │  │  轉發到: 127.0.0.1:18789                 │  │             │
│  │  └─────────────┬────────────────────────────┘  │             │
│  │                │ Localhost                      │             │
│  │                ▼                                │             │
│  │  ┌──────────────────────────────────────────┐  │             │
│  │  │  OpenClaw Gateway (Node.js)             │  │             │
│  │  │  - WebSocket: ws://127.0.0.1:18789      │  │             │
│  │  │  - 僅綁定 loopback 接口                  │  │             │
│  │  │  - Token 認證                            │  │             │
│  │  │  - 裝置配對機制                          │  │             │
│  │  └──────────────────────────────────────────┘  │             │
│  │                                                 │             │
│  │  持久化存儲 (volume mount)                      │             │
│  │  /root/.openclaw ← ./data/                    │             │
│  └─────────────────────────────────────────────────┘             │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## 核心組件

### 1. Traefik (v3.0)

**職責：**
- 作為 HTTP/HTTPS 入口點
- TLS 證書管理和終止
- 基於主機名的路由
- Docker 服務自動發現

**設定要點：**
- 監聽連接埠：80 (HTTP)、443 (HTTPS)、8080 (Dashboard)
- 通過 Docker socket 自動發現服務
- 讀取 `traefik_dynamic.yml` 加載 TLS 證書
- 僅暴露標記為 `traefik.enable=true` 的服務

**路由規則：**
```yaml
traefik.http.routers.openclaw.rule: Host(`openclaw.local`) || Host(`localhost`)
traefik.http.routers.openclaw.entrypoints: websecure
traefik.http.routers.openclaw.tls: true
traefik.http.services.openclaw.loadbalancer.server.port: 18790
```

### 2. OpenClaw Gateway

**基礎鏡像：** `node:22-slim`

**職責：**
- 運行 OpenClaw WebSocket Gateway
- 處理客戶端連接和認證
- 管理 AI 對話會話
- 裝置配對管理

**關鍵特性：**
- **僅 Loopback 綁定：** 出於安全考慮，OpenClaw 默認只綁定到 `127.0.0.1` 和 `[::1]`
- **Token 認證：** 通過環境變量 `OPENCLAW_GATEWAY_TOKEN` 設置
- **裝置配對：** 新裝置首次連接需要手動批準（安全機制）

**Skills 系統：**

OpenClaw 內建 50 個技能插件（skills），通過 ClawHub 管理：

- **Skill 架構：**
  - Skill 存儲在 `/app/skills/` 目錄
  - 每個 skill 包含 `SKILL.md` 描述文件
  - Skills 可以依賴外部 CLI 工具（如 gemini-cli）
  
- **Skill 管理：**
  ```bash
  # 列出所有 skills（包括狀態）
  openclaw skills list
  
  # 安裝新 skill
  npx clawhub install <skill-name>
  
  # 搜尋可用 skills
  npx clawhub search <keyword>
  ```

- **預裝 Skills：**
  - ✓ `bluebubbles`: BlueBubbles 外部插件
  - ✓ `healthcheck`: 安全加固和風險評估
  - ✓ `skill-creator`: 建立自定義 skills
  - ✓ `gemini`: Google Gemini AI 問答（需設定 `GEMINI_API_KEY`）

- **Gemini AI Skill：**
  - **功能：** 一次性問答、內容總結、文本產生
  - **依賴：** `gemini-cli`（通過 npm 自動安裝）
  - **設定：** 需要 `GEMINI_API_KEY` 環境變量
  - **使用：** `gemini "your prompt here"`
  - **免費配額：** 從 https://aistudio.google.com/api-keys 獲取 API Key

**啟動流程：**
1. 安裝系統依賴（git, socat, net-tools）
2. 全域安裝 openclaw
3. 全域安裝 @google/gemini-cli（為 Gemini skill 準備）
4. 後台啟動 OpenClaw Gateway
5. 等待連接埠 18789 就緒
6. 啟動 Socat 代理監聽 18790

### 3. Socat TCP 代理

**為什麼需要 Socat？**

OpenClaw Gateway 硬編碼為只監聽 localhost 接口，無法通過 `--host` 參數或環境變量更改。為了讓 Docker 網路中的其他容器（Traefik）能存取，需要一個 TCP 轉發層。

**工作原理：**
```bash
socat TCP-LISTEN:18790,fork,reuseaddr,bind=0.0.0.0 TCP:127.0.0.1:18789
```

- 在所有網路接口 (`0.0.0.0`) 監聽 18790 連接埠
- 將流量轉發到本地 18789 連接埠（OpenClaw 實際監聽連接埠）
- `fork`：為每個連接建立新進程
- `reuseaddr`：允許快速重啟

## 網路流量流程

1. **客戶端請求：** 瀏覽器存取 `https://openclaw.local/`
2. **DNS 解析：** `/etc/hosts` 將 `openclaw.local` 解析為 `127.0.0.1`
3. **TLS 握手：** Traefik 使用自簽名證書完成 HTTPS 握手
4. **路由匹配：** Traefik 根據 Host header 將請求路由到 `openclaw_gateway` 服務
5. **HTTP 轉發：** Traefik 通過 Docker 網路將請求轉發到 `openclaw_gateway:18790`
6. **TCP 代理：** Socat 接收請求並轉發到 `127.0.0.1:18789`
7. **WebSocket 升級：** OpenClaw Gateway 處理 WebSocket 連接
8. **認證與配對：** 
   - 驗證 Gateway Token
   - 檢查裝置是否已配對
   - 如未配對，發送配對請求並等待批準

## 資料持久化

### Volume Mount: `./data` → `/root/.openclaw`

**持久化內容：**
```
data/
├── config.json              # Gateway 設定（mode, bind, trustedProxies）
├── credentials.json         # OAuth 憑證（Google 等）
├── update-check.json        # 版本檢查緩存
├── devices/
│   ├── paired.json         # 已批準的裝置列表
│   └── pending.json        # 待批準的配對請求
├── cron/
│   ├── jobs.json          # 定時任務設定
│   └── jobs.json.bak      # 備份
└── canvas/
    └── index.html         # Canvas UI 文件
```

## 安全機制

### 1. Token 認證
- 環境變量：`OPENCLAW_GATEWAY_TOKEN`
- 客戶端連接時必須提供正確的 token
- Token 應當足夠複雜且保密

### 2. 裝置配對
- 新裝置首次連接時會被要求配對
- 配對請求儲存在 `devices/pending.json`
- 管理員必須手動批準：`openclaw devices approve <request-id>`
- 已批準裝置信息儲存在 `devices/paired.json`

### 3. TLS 加密
- 使用自簽名證書（開發環境）
- 生產環境應替換為有效證書（Let's Encrypt）

### 4. Trusted Proxies
設定代理信任列表以正確識別客戶端 IP：
```json
{
  "gateway": {
    "trustedProxies": ["127.0.0.1", "0.0.0.0/0", "::/0"]
  }
}
```

## 連接埠分配

| 服務 | 容器連接埠 | 宿主連接埠 | 協議 | 用途 |
|------|---------|---------|------|------|
| Traefik | 80 | 80 | HTTP | HTTP 入口（可重定向到 HTTPS） |
| Traefik | 443 | 443 | HTTPS | HTTPS 入口 |
| Traefik | 8080 | 8080 | HTTP | Traefik Dashboard |
| OpenClaw | 18789 | - | WebSocket | OpenClaw Gateway（僅 localhost） |
| Socat | 18790 | - | TCP | TCP 代理層（Docker 網路內存取） |

## 環境變量

### OpenClaw 容器

| 變量 | 默認值 | 說明 |
|------|--------|------|
| `TZ` | `Asia/Taipei` | 時區設置 |
| `OPENCLAW_GATEWAY_TOKEN` | `your_secure_token` | Gateway 認證 Token（**需修改**） |
| `OPENCLAW_GATEWAY_PORT` | `18789` | OpenClaw 監聽連接埠 |
| `GEMINI_API_KEY` | - | Google Gemini API Key（可選，啟用 AI 功能） |

## 設定文件詳解

### docker-compose.yml

定義了兩個服務和一個網路：
- `traefik`：反向代理服務
- `openclaw`：OpenClaw Gateway 服務
- `openclaw_net`：橋接網路，連接兩個服務

### traefik_dynamic.yml

動態設定 Traefik 的 TLS 證書：
```yaml
tls:
  certificates:
    - certFile: /etc/traefik/certs/local-cert.pem
      keyFile: /etc/traefik/certs/local-key.pem
```

### data/config.json

OpenClaw Gateway 核心設定：
```json
{
  "gateway": {
    "mode": "local",                                    # 運行模式
    "bind": "loopback",                                 # 綁定模式（僅本地）
    "trustedProxies": ["127.0.0.1", "0.0.0.0/0", "::/0"] # 信任的代理列表
  }
}
```

**重要：** `trustedProxies` 設定是解決 "pairing required" 錯誤的關鍵。

### start-openclaw.sh

容器啟動腳本，執行順序：
1. 更新 apt 包列表
2. 安裝依賴：git、socat、net-tools
3. 全局安裝 openclaw npm 包
4. 後台啟動 OpenClaw Gateway
5. 等待 18789 連接埠就緒（最多 60 秒）
6. 啟動 socat 代理（前台運行，保持容器存活）

## 故障排除

### 問題 1: "Bad Gateway" 錯誤

**症狀：** 瀏覽器存取 `https://openclaw.local/` 返回 502 Bad Gateway

**可能原因：**
- OpenClaw 容器未就緒
- Socat 代理未啟動
- 連接埠綁定失敗

**排查步驟：**
```bash
# 檢查容器狀態
docker ps

# 查看 OpenClaw 日誌
docker logs openclaw_gateway --tail 50

# 確認連接埠綁定
docker exec openclaw_gateway netstat -tln | grep 18789
docker exec openclaw_gateway netstat -tln | grep 18790
```

### 問題 2: "disconnected (1008): pairing required"

**症狀：** WebSocket 連接後立即斷開，錯誤代碼 1008

**原因：** 
- 裝置未配對
- 或 `trustedProxies` 設定未生效

**解決方案：**
```bash
# 1. 確認 trustedProxies 設定
docker exec openclaw_gateway openclaw config get gateway.trustedProxies

# 2. 查看待配對裝置
docker exec openclaw_gateway openclaw devices list

# 3. 批準配對請求
docker exec openclaw_gateway openclaw devices approve <REQUEST_ID>
```

### 問題 3: TLS 證書警告

**症狀：** 瀏覽器顯示 "您的連接不是私密連接"

**原因：** 使用自簽名證書

**解決方案：**
- 開發環境：點擊 "繼續前往"（不安全）
- 生產環境：使用 Let's Encrypt 或購買有效證書

### 問題 4: 設定更改未生效

**症狀：** 修改 `data/config.json` 後設定未生效

**解決方案：**
```bash
# 重啟容器以重新加載設定
docker compose restart openclaw

# 或者手動觸發設定重新加載（如果 OpenClaw 正在運行）
docker exec openclaw_gateway openclaw config set gateway.mode local
```

## 擴展與優化

### 1. 添加更多域名

修改 `docker-compose.yml` 中的路由規則：
```yaml
traefik.http.routers.openclaw.rule: Host(`openclaw.local`) || Host(`openclaw.example.com`)
```

### 2. 整合 Cloudflare Tunnel

取消註釋 `docker-compose.yml` 中的 `cf_tunnel` 服務，設置環境變量：
```bash
export CF_TUNNEL_TOKEN="your-cloudflare-tunnel-token"
docker compose up -d cf_tunnel
```

### 3. 啟用日誌輪轉

OpenClaw 日誌儲存在 `/tmp/openclaw/openclaw-YYYY-MM-DD.log`，建議設定日誌清理策略。

### 4. 性能優化

- 使用持久化的 npm 緩存卷減少每次安裝時間
- 構建自定義 Docker 鏡像預裝 openclaw（避免每次啟動都安裝）

## 參考資源

- [OpenClaw 官方文檔](https://docs.openclaw.ai/)
- [Traefik 文檔](https://doc.traefik.io/traefik/)
- [Socat 手冊](http://www.dest-unreach.org/socat/doc/socat.html)
