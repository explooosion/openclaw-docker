# 腳本目錄

此目錄包含 OpenClaw 專案的管理和維護腳本。

## 可用腳本

### Skills 管理

- **`install-skill.sh`** - 安裝自訂 Skill
  ```bash
  ./scripts/install-skill.sh skill-name https://github.com/user/repo.git
  ```

- **`update-skills.sh`** - 批次更新所有已安裝的 Skills
  ```bash
  ./scripts/update-skills.sh
  ```

- **`test-skill.sh`** - 測試指定的 Skill
  ```bash
  ./scripts/test-skill.sh skill-name
  ```

### Telegram Bot 診斷

- **`telegram-health-check.sh`** - 檢查 Telegram Bot 健康狀態
  ```bash
  ./scripts/telegram-health-check.sh
  ```

- **`test-telegram-bot.sh`** - 測試 Telegram Bot 整合
  ```bash
  ./scripts/test-telegram-bot.sh
  ```

## 使用方式

### 確保腳本可執行

```bash
chmod +x scripts/*.sh
```

### 執行腳本

```bash
# 直接執行
./scripts/install-skill.sh args

# 或使用 npm scripts（推薦）
npm run skills:install
```

## NPM Scripts 整合

大部分腳本功能已整合到 `package.json` 的 scripts 中：

```bash
npm run skills:list      # 列出 Skills
npm run skills:install   # 安裝 Skill
npm run test:telegram    # 測試 Telegram
```

查看完整列表：
```bash
npm run
```

## 開發腳本

添加新的管理腳本時：

1. 放置在此目錄
2. 添加執行權限：`chmod +x scripts/your-script.sh`
3. 更新此 README
4. （可選）添加到 `package.json` 的 scripts

## 注意事項

- 所有腳本應使用 `#!/bin/bash` shebang
- 包含錯誤處理 (`set -e`)
- 提供清晰的輸出訊息
- 支援參數驗證

## 相關文件

- [Skills 管理指南](../docs/guides/SKILLS_MANAGEMENT.md)
- [Telegram 設定指南](../docs/guides/TELEGRAM_SETUP.md)
