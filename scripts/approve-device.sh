#!/bin/bash
# OpenClaw 设备配对管理脚本

set -e

CONTAINER_NAME="openclaw_gateway"

echo "📱 OpenClaw 设备配对管理工具"
echo "================================"
echo ""

# 检查容器是否运行
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "❌ 错误: OpenClaw Gateway 容器未运行"
    echo "   请先运行: docker compose up -d"
    exit 1
fi

# 显示待批准的配对请求
echo "📋 待批准的设备配对请求："
echo ""

PENDING_OUTPUT=$(docker exec $CONTAINER_NAME openclaw devices list 2>/dev/null || echo "")
echo "$PENDING_OUTPUT" | grep -A 10 "Pending" || echo "  (无)"

# 统计待批准数量（查找 UUID 格式的 Request ID）
PENDING_COUNT=$(echo "$PENDING_OUTPUT" | grep -A 20 "Pending" | grep -oE '[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}' | wc -l | tr -d ' ')

if [ "$PENDING_COUNT" -eq 0 ]; then
    echo ""
    echo "✅ 没有待批准的配对请求"
    echo ""
    echo "💡 使用说明："
    echo "   1. 在浏览器打开 OpenClaw Web 界面"
    echo "   2. 点击连接按钮"
    echo "   3. 再次运行此脚本进行批准"
    exit 0
fi

echo ""
echo "─────────────────────────────────────"
echo ""

# 询问是否批准
read -p "是否批准所有待处理的配对请求？[y/N] " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    # 提取所有待批准的 Request ID
    REQUEST_IDS=$(echo "$PENDING_OUTPUT" | \
        grep -A 20 "Pending" | \
        grep -oE '[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}')
    
    if [ -z "$REQUEST_IDS" ]; then
        echo "⚠️  未找到有效的配对请求 ID"
        exit 1
    fi
    
    echo ""
    for REQUEST_ID in $REQUEST_IDS; do
        echo "✓ 批准设备: $REQUEST_ID"
        docker exec $CONTAINER_NAME openclaw devices approve "$REQUEST_ID" 2>&1 || echo "  ⚠️ 批准失败"
    done
    
    echo ""
    echo "✅ 所有设备配对请求已批准！"
    echo "   请在浏览器中刷新页面"
else
    echo "❌ 已取消操作"
fi

echo ""
