#!/bin/bash
################################################################################
# 快速測試內建 Weather Skill
################################################################################

echo "🌤️ 測試 Weather Skill (內建，免費)"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 測試台北天氣
echo "📍 台北天氣:"
docker exec openclaw_gateway bash -c "curl -s 'wttr.in/Taipei?format=3'"
echo ""

# 測試東京天氣
echo "📍 東京天氣:"
docker exec openclaw_gateway bash -c "curl -s 'wttr.in/Tokyo?format=3'"
echo ""

# 測試紐約天氣
echo "📍 紐約天氣:"
docker exec openclaw_gateway bash -c "curl -s 'wttr.in/NewYork?format=3'"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "✅ Weather Skill 測試完成"
echo ""
echo "在 Telegram 測試："
echo "  '台北今天天氣如何？'"
echo "  '東京天氣'"
echo "  'weather in new york'"
