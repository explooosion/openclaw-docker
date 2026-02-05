# OpenClaw Skills 管理指南

## 📦 Skills 架構

OpenClaw 支援透過 Skills 系統擴展功能。Skills 可以透過以下方式安裝：

### 方式 1：Volume Mount（推薦）

將外部 Skills 掛載到容器中，便於開發和管理。

#### 設定步驟

1. **建立 Skills 目錄結構**

```bash
mkdir -p skills-custom
cd skills-custom
```

2. **安裝 Skill（從 awesome-openclaw-skills）**

```bash
# 範例：安裝 Home Assistant Skill
git clone https://github.com/VoltAgent/skill-home-assistant.git

# 或使用 Git submodule（推薦用於版本管理）
git submodule add https://github.com/VoltAgent/skill-home-assistant.git skills-custom/skill-home-assistant
```

3. **更新 docker-compose.yml**

在 `openclaw` 服務中添加 volume：

```yaml
services:
  openclaw:
    volumes:
      - ./data:/root/.openclaw
      - ./gog-config:/root/.config/gogcli
      - ./start-openclaw.sh:/start-openclaw.sh:ro
      - ./skills-custom:/root/.openclaw/skills/custom:ro  # 新增這行
```

4. **重啟容器**

```bash
docker compose restart openclaw
```

5. **驗證 Skill**

```bash
docker exec openclaw_gateway openclaw skills list
```

### 方式 2：內建安裝（容器內）

直接在容器內安裝 Skills。

```bash
# 進入容器
docker exec -it openclaw_gateway sh

# 使用 OpenClaw CLI 安裝（如果 Skill 支援）
openclaw skills install <skill-name>

# 或手動克隆
cd /root/.openclaw/skills
git clone https://github.com/VoltAgent/skill-<name>.git
```

**缺點**：容器重建後會遺失（除非使用持久化 volume）

### 方式 3：使用安裝腳本（推薦生產環境）

建立自動化腳本管理 Skills。

## 🎯 Skills 管理腳本

### 快速安裝腳本

建立 `install-skill.sh`：

```bash
#!/bin/bash
# Skills 快速安裝腳本

SKILL_NAME=$1
SKILL_REPO=$2
SKILLS_DIR="./skills-custom"

if [ -z "$SKILL_NAME" ] || [ -z "$SKILL_REPO" ]; then
    echo "使用方式: ./install-skill.sh <skill-name> <github-repo-url>"
    echo "範例: ./install-skill.sh home-assistant https://github.com/VoltAgent/skill-home-assistant.git"
    exit 1
fi

# 建立目錄
mkdir -p "$SKILLS_DIR"

# 克隆 Skill
cd "$SKILLS_DIR"
git clone "$SKILL_REPO" "$SKILL_NAME"

# 檢查是否有 requirements.txt
if [ -f "$SKILL_NAME/requirements.txt" ]; then
    echo "發現 requirements.txt，請在容器內安裝依賴："
    echo "  docker exec openclaw_gateway pip install -r /root/.openclaw/skills/custom/$SKILL_NAME/requirements.txt"
fi

# 重啟容器
cd ..
echo "重啟 OpenClaw 容器..."
docker compose restart openclaw

echo "✓ Skill '$SKILL_NAME' 安裝完成"
echo "驗證安裝: docker exec openclaw_gateway openclaw skills list"
```

使其可執行：

```bash
chmod +x install-skill.sh
```

使用範例：

```bash
./install-skill.sh calendar https://github.com/VoltAgent/skill-calendar.git
./install-skill.sh spotify https://github.com/VoltAgent/skill-spotify.git
```

## 📚 推薦的 Skills（來自 awesome-openclaw-skills）

### 🏠 智慧家居

- **Home Assistant** - 完整的智慧家居控制
- **Philips Hue** - 智慧燈光控制
- **Nest** - Nest 溫控器和攝影機

### 📅 生產力工具

- **Calendar** - 行事曆管理（Google Calendar、Outlook）
- **Todoist** - 任務管理
- **Notion** - 筆記本和資料庫

### 🎵 媒體

- **Spotify** - 音樂播放控制
- **YouTube** - 影片搜尋和播放
- **Plex** - 媒體伺服器控制

### 💬 通訊

- **Slack** - Slack 整合
- **Discord** - Discord bot 功能
- **Email** - 郵件管理

### 🔧 開發工具

- **Docker** - 容器管理
- **Jenkins** - CI/CD 整合
- **Jira** - 問題追蹤

## 🛠️ 進階設定

### 使用 Git Submodules 管理 Skills

適合需要版本控制的場景：

```bash
# 初始化 submodules
git submodule init

# 添加 Skill 作為 submodule
git submodule add https://github.com/VoltAgent/skill-home-assistant.git skills-custom/home-assistant

# 更新所有 submodules
git submodule update --remote --merge

# 克隆包含 submodules 的專案
git clone --recurse-submodules <your-repo-url>
```

### Skills 設定文件

每個 Skill 可能需要設定，通常在以下位置：

```
data/agents/main/skills/<skill-name>/
  ├── config.json          # Skill 設定
  ├── credentials.json     # API 憑證（敏感）
  └── settings.json        # 使用者設定
```

確保這些檔案在 `.gitignore` 中被排除。

### 自動更新 Skills

建立 `update-skills.sh`：

```bash
#!/bin/bash
# 更新所有已安裝的 Skills

SKILLS_DIR="./skills-custom"

if [ ! -d "$SKILLS_DIR" ]; then
    echo "Skills 目錄不存在"
    exit 1
fi

cd "$SKILLS_DIR"

for skill in */; do
    if [ -d "$skill/.git" ]; then
        echo "更新 $skill..."
        cd "$skill"
        git pull origin main || git pull origin master
        cd ..
    fi
done

cd ..
echo "重啟容器以應用更新..."
docker compose restart openclaw
```

## 🔒 安全考量

1. **僅安裝信任的 Skills**
   - 檢查 Skill 的原始碼
   - 驗證來源的可靠性
   - 查看其他使用者的評價

2. **隔離敏感資訊**
   - Skills 設定應存放在 `data/` 目錄
   - 使用環境變數傳遞 API 金鑰
   - 不要在 Skills 中硬編碼憑證

3. **權限控制**
   - Skills 以容器使用者權限執行
   - 限制 Skills 的檔案系統存取
   - 審查 Skills 的網路存取需求

## 🐛 故障排除

### Skill 未顯示在列表中

```bash
# 檢查 Skills 目錄權限
ls -la skills-custom/

# 檢查容器內的 mount
docker exec openclaw_gateway ls -la /root/.openclaw/skills/custom/

# 查看容器日誌
docker logs openclaw_gateway | grep -i skill
```

### Skill 無法載入

```bash
# 檢查 Skill 結構
docker exec openclaw_gateway cat /root/.openclaw/skills/custom/<skill-name>/skill.json

# 驗證依賴
docker exec openclaw_gateway openclaw skills validate <skill-name>
```

### 依賴安裝問題

```bash
# 在容器內安裝 Python 依賴
docker exec openclaw_gateway pip install -r /root/.openclaw/skills/custom/<skill-name>/requirements.txt

# 安裝 Node.js 依賴
docker exec openclaw_gateway npm install --prefix /root/.openclaw/skills/custom/<skill-name>
```

## 📖 相關資源

- **Awesome OpenClaw Skills**: https://github.com/VoltAgent/awesome-openclaw-skills
- **Skill 開發文件**: [建立自定義 Skill](./SKILL_DEVELOPMENT.md)
- **社群 Skills 庫**: https://skills.openclaw.io （如果存在）

## 🤝 貢獻

發現好用的 Skill？歡迎：

1. Fork awesome-openclaw-skills 專案
2. 添加您的 Skill 到列表
3. 提交 Pull Request
4. 分享您的經驗

---

如有問題，請查看 [Skills 整合報告](./SKILLS_INTEGRATION_REPORT.md) 或在 GitHub Discussions 提問。
