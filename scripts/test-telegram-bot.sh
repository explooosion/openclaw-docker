#!/bin/bash

# Telegram Bot 測試腳本
# 用於驗證 Bot Token 是否有效

set -e

echo "🔍 測試 Telegram Bot 配置..."
echo ""

# 檢查環境變數
if [ -z "$TELEGRAM_BOT_TOKEN" ]; then
    echo "❌ 錯誤：TELEGRAM_BOT_TOKEN 未設定"
    echo ""
    echo "請執行："
    echo "  export TELEGRAM_BOT_TOKEN=你的Bot Token"
    echo "或在 .env 中設定"
    exit 1
fi

echo "✅ TELEGRAM_BOT_TOKEN 已設定"
echo ""

# 測試 Token 有效性
echo "📡 連接 Telegram API..."
RESPONSE=$(curl -s "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getMe")

# 檢查回應
if echo "$RESPONSE" | grep -q '"ok":true'; then
    echo "✅ Token 有效！"
    echo ""
    echo "📊 Bot 資訊："
    echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"
    echo ""
    echo "🎉 測試成功！你可以啟動 Bot 了："
    echo "   docker compose up -d telegram-bot"
else
    echo "❌ Token 無效或網路錯誤"
    echo ""
    echo "錯誤訊息："
    echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"
    exit 1
fi
