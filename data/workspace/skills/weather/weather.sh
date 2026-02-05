#!/bin/bash
################################################################################
# Weather Skill - OpenWeatherMap Integration
# 
# 使用 OpenWeatherMap API 查询天气信息
################################################################################

set -e

# 从环境变量读取 API Key
API_KEY="${OPENWEATHER_API_KEY:-}"

if [ -z "$API_KEY" ]; then
    echo "错误: 未设置 OPENWEATHER_API_KEY 环境变量"
    echo "请在 .env 中添加: OPENWEATHER_API_KEY=your_key"
    exit 1
fi

# 获取城市参数
CITY="${1:-Taipei}"

# API 端点
API_URL="https://api.openweathermap.org/data/2.5/weather"

# 发送请求
RESPONSE=$(curl -s "${API_URL}?q=${CITY}&appid=${API_KEY}&units=metric&lang=zh_tw" || echo "")

if [ -z "$RESPONSE" ]; then
    echo "错误: 无法连接到 OpenWeatherMap API"
    exit 1
fi

# 检查错误
if echo "$RESPONSE" | grep -q '"cod":"404"'; then
    echo "错误: 找不到城市 '${CITY}'"
    exit 1
fi

# 解析 JSON 并输出
echo "$RESPONSE" | python3 -c "
import sys, json

try:
    data = json.load(sys.stdin)
    
    city = data['name']
    temp = data['main']['temp']
    feels_like = data['main']['feels_like']
    humidity = data['main']['humidity']
    description = data['weather'][0]['description']
    
    print(f'📍 {city} 天气')
    print(f'🌡️  温度: {temp}°C (体感 {feels_like}°C)')
    print(f'💧 湿度: {humidity}%')
    print(f'☁️  状况: {description}')
    
except Exception as e:
    print(f'错误: 无法解析天气数据 - {e}')
    sys.exit(1)
"
