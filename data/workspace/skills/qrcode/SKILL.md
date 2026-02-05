# QR Code Generator Skill

產生二维码图片的 Skill。

## 功能

- 将文本或 URL 转换为二维码
- 支援自定义输出路径
- 高分辨率输出

## 依赖

需要安装 `qrencode`：

```bash
# macOS
brew install qrencode

# Ubuntu/Debian
apt-get install qrencode

# Alpine (Docker)
apk add qrencode
```

## 使用示例

```bash
# 產生二维码
openclaw qrcode "https://example.com"

# 指定输出路径
openclaw qrcode "Hello World" /tmp/my-qrcode.png

# 在 Telegram 中
產生二维码：https://github.com
制作 QR Code: 联系我们 12345678
```

## 設定

无需额外設定，完全免费。

## 测试

```bash
# 测试是否安装成功
docker exec openclaw_gateway qrencode --version

# 测试 Skill
./scripts/test-skill.sh qrcode
```
