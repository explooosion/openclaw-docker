#!/bin/bash
################################################################################
# QR Code Generator Skill
# 
# 使用 qrencode 生成二维码
################################################################################

set -e

# 检查 qrencode 是否安装
if ! command -v qrencode &> /dev/null; then
    echo "错误: qrencode 未安装"
    echo "安装方法:"
    echo "  macOS: brew install qrencode"
    echo "  Ubuntu: apt-get install qrencode"
    echo "  Alpine: apk add qrencode"
    exit 1
fi

# 获取参数
TEXT="${1:-https://example.com}"
OUTPUT="${2:-/tmp/qrcode.png}"

# 生成二维码
qrencode -o "$OUTPUT" -s 10 -m 2 "$TEXT"

if [ -f "$OUTPUT" ]; then
    echo "✅ 二维码已生成: $OUTPUT"
    echo "📝 内容: $TEXT"
    ls -lh "$OUTPUT"
else
    echo "❌ 生成失败"
    exit 1
fi
