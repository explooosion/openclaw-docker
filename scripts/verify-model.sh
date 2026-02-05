#!/bin/bash
################################################################################
# 模型配置验证脚本
################################################################################

echo "🔍 验证 OpenClaw 模型配置"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 1. 宿主机配置
echo "📁 宿主机配置 (data/config.json):"
if [ -f "data/config.json" ]; then
    cat data/config.json | jq -r '.agents.main.model'
else
    echo "❌ 文件不存在"
fi
echo ""

# 2. 容器内配置
echo "🐳 容器内配置 (/root/.openclaw/config.json):"
docker exec openclaw_gateway cat /root/.openclaw/config.json 2>/dev/null | jq -r '.agents.main.model' || echo "❌ 容器未運行或配置文件不存在"
echo ""

# 3. 完整配置
echo "📋 完整配置内容:"
docker exec openclaw_gateway cat /root/.openclaw/config.json 2>/dev/null | jq . || echo "❌ 无法读取"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "✅ 验证完成"
echo ""
echo "💡 在 Telegram 测试："
echo "   向 Bot 发送: '你现在使用什么模型？'"
