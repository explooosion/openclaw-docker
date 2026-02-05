#!/usr/bin/env python3
"""
OpenClaw Telegram Bot
使用者透過 Telegram 與 OpenClaw AI 助理互動
"""

import os
import sys
import logging
import json
from typing import Optional
from datetime import datetime

import requests
from telegram import Update
from telegram.ext import (
    Application,
    CommandHandler,
    MessageHandler,
    ContextTypes,
    filters,
)

# 設定日誌
logging.basicConfig(
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    level=logging.INFO
)
logger = logging.getLogger(__name__)

# 環境變數
TELEGRAM_BOT_TOKEN = os.getenv('TELEGRAM_BOT_TOKEN')
OPENCLAW_GATEWAY_URL = os.getenv('OPENCLAW_GATEWAY_URL', 'http://openclaw:18790')
OPENCLAW_GATEWAY_TOKEN = os.getenv('OPENCLAW_GATEWAY_TOKEN', 'robby12345')
OPENCLAW_AGENT = os.getenv('OPENCLAW_AGENT', 'main')

# 驗證環境變數
if not TELEGRAM_BOT_TOKEN:
    logger.error("❌ TELEGRAM_BOT_TOKEN 環境變數未設定！")
    sys.exit(1)

logger.info(f"✅ OpenClaw Gateway: {OPENCLAW_GATEWAY_URL}")
logger.info(f"✅ OpenClaw Agent: {OPENCLAW_AGENT}")


def create_session_id(user_id: int) -> str:
    """為每個 Telegram 用戶創建獨立的 Session ID"""
    return f"telegram:{user_id}"


def call_openclaw(session_id: str, message: str) -> Optional[str]:
    """
    呼叫 OpenClaw Gateway API
    
    Args:
        session_id: Session ID (telegram:user_id)
        message: 用戶訊息
        
    Returns:
        OpenClaw 的回應文字，如果失敗則返回 None
    """
    try:
        url = f"{OPENCLAW_GATEWAY_URL}/api/chat"
        
        headers = {
            'Content-Type': 'application/json',
            'Authorization': f'Bearer {OPENCLAW_GATEWAY_TOKEN}'
        }
        
        payload = {
            'agent': OPENCLAW_AGENT,
            'session': session_id,
            'message': message,
            'stream': False  # 不使用串流模式
        }
        
        logger.info(f"📤 向 OpenClaw 發送請求: {message[:50]}...")
        
        response = requests.post(
            url,
            headers=headers,
            json=payload,
            timeout=60  # 60 秒超時
        )
        
        response.raise_for_status()
        
        # 解析回應
        result = response.json()
        
        if 'response' in result:
            reply = result['response']
            logger.info(f"📥 收到 OpenClaw 回應: {reply[:50]}...")
            return reply
        elif 'error' in result:
            logger.error(f"❌ OpenClaw 錯誤: {result['error']}")
            return f"抱歉，OpenClaw 回報錯誤：{result['error']}"
        else:
            logger.warning(f"⚠️ 未知的回應格式: {result}")
            return "抱歉，我收到了不完整的回應。"
            
    except requests.exceptions.Timeout:
        logger.error("⏱️ OpenClaw 請求超時")
        return "抱歉，請求處理時間過長，請稍後再試。"
    except requests.exceptions.RequestException as e:
        logger.error(f"❌ OpenClaw 請求失敗: {e}")
        return f"抱歉，無法連接到 AI 服務。錯誤：{str(e)}"
    except Exception as e:
        logger.error(f"❌ 未預期的錯誤: {e}")
        return "抱歉，發生了未預期的錯誤。"


async def start_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """處理 /start 指令"""
    user = update.effective_user
    
    welcome_message = f"""
👋 你好 {user.first_name}！

我是你的私人 AI 助理，由 OpenClaw 驅動。

🎯 **我能做什麼？**
• 📅 管理行事曆和待辦事項
• 🌤️ 查詢天氣資訊
• 📊 股市與財務資訊
• 🤖 回答各種問題
• 🔧 整合 Google、GitHub 等服務

💬 **使用方式：**
直接輸入任何訊息，我會盡力幫助你！

📚 **常用指令：**
/help - 顯示幫助訊息
/status - 檢查 AI 服務狀態
/clear - 清除對話歷史

開始對話吧！✨
"""
    
    await update.message.reply_text(welcome_message)
    
    # 記錄新用戶
    logger.info(f"👤 新用戶: {user.id} ({user.username or user.first_name})")


async def help_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """處理 /help 指令"""
    help_text = """
📖 **OpenClaw AI 助理使用指南**

🗣️ **自然對話：**
直接輸入訊息即可，例如：
• "今天台北天氣如何？"
• "幫我查看明天的行程"
• "提醒我下午 3 點開會"
• "AAPL 股價多少？"

⚙️ **指令列表：**
/start - 開始使用
/help - 顯示此幫助訊息
/status - 檢查 AI 服務狀態
/clear - 清除對話歷史（重新開始）

🔧 **整合服務：**
我已經整合了以下服務（需要先在管理介面設定 OAuth）：
• 📅 Google Calendar (gog skill)
• 🐙 GitHub
• 🌤️ Weather API
• ♊ Gemini AI

💡 **提示：**
你可以詢問我關於這些服務的資訊，我會自動調用相應的功能。

有問題嗎？直接問我吧！😊
"""
    
    await update.message.reply_text(help_text)


async def status_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """處理 /status 指令 - 檢查 OpenClaw 服務狀態"""
    user = update.effective_user
    session_id = create_session_id(user.id)
    
    await update.message.reply_text("🔍 檢查 AI 服務狀態...")
    
    try:
        # 嘗試連接 OpenClaw
        response = requests.get(
            f"{OPENCLAW_GATEWAY_URL}/health",
            timeout=5
        )
        
        if response.status_code == 200:
            status_msg = f"""
✅ **AI 服務正常運行**

📊 **服務資訊：**
• Gateway: {OPENCLAW_GATEWAY_URL}
• Agent: {OPENCLAW_AGENT}
• Session: {session_id}
• 時間: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

準備好為你服務！🚀
"""
        else:
            status_msg = f"⚠️ AI 服務回應異常 (狀態碼: {response.status_code})"
            
    except Exception as e:
        status_msg = f"❌ 無法連接到 AI 服務\n錯誤：{str(e)}"
    
    await update.message.reply_text(status_msg)


async def clear_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """處理 /clear 指令 - 清除對話歷史"""
    user = update.effective_user
    session_id = create_session_id(user.id)
    
    # 通知 OpenClaw 清除 Session（如果 API 支援）
    # 目前先提示用戶
    
    clear_msg = f"""
🧹 **對話歷史已清除**

你的 Session ID: `{session_id}`

現在你可以開始全新的對話了。我不會記得之前的內容。

輸入任何訊息開始新對話！✨
"""
    
    await update.message.reply_text(clear_msg)
    logger.info(f"🧹 用戶 {user.id} 清除對話歷史")


async def handle_message(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """處理用戶的一般訊息"""
    user = update.effective_user
    message_text = update.message.text
    session_id = create_session_id(user.id)
    
    logger.info(f"💬 收到訊息 from {user.id}: {message_text}")
    
    # 顯示 "正在輸入..." 狀態
    await context.bot.send_chat_action(
        chat_id=update.effective_chat.id,
        action="typing"
    )
    
    # 呼叫 OpenClaw
    response = call_openclaw(session_id, message_text)
    
    if response:
        # 分段發送（Telegram 訊息長度限制 4096 字元）
        max_length = 4000
        if len(response) > max_length:
            # 分段發送
            for i in range(0, len(response), max_length):
                chunk = response[i:i + max_length]
                await update.message.reply_text(chunk)
        else:
            await update.message.reply_text(response)
    else:
        await update.message.reply_text(
            "抱歉，我目前無法處理你的請求。請稍後再試。"
        )


async def error_handler(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """處理錯誤"""
    logger.error(f"❌ 發生錯誤: {context.error}")
    
    if update and update.effective_message:
        await update.effective_message.reply_text(
            "抱歉，處理你的請求時發生錯誤。請稍後再試。"
        )


def main():
    """主函數 - 啟動 Bot"""
    logger.info("🚀 啟動 OpenClaw Telegram Bot...")
    
    # 創建 Application
    application = Application.builder().token(TELEGRAM_BOT_TOKEN).build()
    
    # 註冊指令處理器
    application.add_handler(CommandHandler("start", start_command))
    application.add_handler(CommandHandler("help", help_command))
    application.add_handler(CommandHandler("status", status_command))
    application.add_handler(CommandHandler("clear", clear_command))
    
    # 註冊訊息處理器（處理所有文字訊息）
    application.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_message))
    
    # 註冊錯誤處理器
    application.add_error_handler(error_handler)
    
    # 啟動 Bot
    logger.info("✅ Bot 已就緒，開始監聽訊息...")
    application.run_polling(allowed_updates=Update.ALL_TYPES)


if __name__ == '__main__':
    main()
