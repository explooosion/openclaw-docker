# Weather Skill

基于 OpenWeatherMap API 的天气查詢 Skill。

## 功能

- 查詢指定城市的当前天气
- 支援中文城市名称
- 显示温度、湿度、天气状况

## 設定

需要在 `.env` 中設定：
```bash
OPENWEATHER_API_KEY=your_api_key_here
```

获取 API Key：https://openweathermap.org/api

## 使用示例

```bash
# 查詢天气
openclaw weather taipei
openclaw weather "New York"

# 在 Telegram 中
台北今天天气如何？
东京天气
```

## Requirements

- curl 或 node-fetch
- OpenWeatherMap API Key (免费层)

## 安装

此 Skill 会在容器啟動时自动加载。

## 测试

```bash
# 测试 Skill 是否加载
docker exec openclaw_gateway openclaw skills info weather

# 直接测试功能
docker exec openclaw_gateway openclaw skills run weather taipei
```
