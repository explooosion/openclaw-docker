#!/bin/bash
################################################################################
# OpenClaw 系統狀態檢查
################################################################################

set -e

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log() { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[⚠]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; }
info() { echo -e "${BLUE}[ℹ]${NC} $1"; }

clear
echo -e "${CYAN}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║     OpenClaw 系統狀態檢查                                     ║
║     System Status Check                                       ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# 檢查容器狀態
echo ""
info "檢查容器狀態..."
echo ""

if docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' | grep openclaw_gateway > /dev/null; then
    log "OpenClaw Gateway - 運行中"
    GATEWAY_STATUS="✅"
else
    error "OpenClaw Gateway - 未運行"
    GATEWAY_STATUS="❌"
fi

if docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' | grep traefik > /dev/null; then
    log "Traefik - 運行中"
    TRAEFIK_STATUS="✅"
else
    warn "Traefik - 未運行"
    TRAEFIK_STATUS="⚠️"
fi

# 檢查 Telegram Bot
echo ""
info "檢查 Telegram 连接..."
echo ""

if docker logs openclaw_gateway 2>&1 | grep "telegram.*starting provider" | tail -1 | grep -q "@"; then
    BOT_NAME=$(docker logs openclaw_gateway 2>&1 | grep "telegram.*starting provider" | tail -1 | sed -n 's/.*(@\([^)]*\)).*/\1/p')
    log "Telegram Bot: $BOT_NAME"
    TELEGRAM_STATUS="✅"
    
    # 檢查是否有冲突
    if docker logs openclaw_gateway 2>&1 | tail -20 | grep -q "getUpdates conflict"; then
        error "警告：检测到 Telegram getUpdates 冲突"
        warn "可能有多个 bot 实例在運行"
        TELEGRAM_STATUS="⚠️ 冲突"
    fi
else
    error "Telegram Bot - 未连接"
    TELEGRAM_STATUS="❌"
fi

# 檢查 AI 模型
echo ""
info "檢查 AI 模型配置..."
echo ""

if docker logs openclaw_gateway 2>&1 | grep "agent model" | tail -1 | grep -q "anthropic"; then
    MODEL=$(docker logs openclaw_gateway 2>&1 | grep "agent model" | tail -1 | sed -n 's/.*agent model: \(.*\)/\1/p' | tr -d ' \n')
    log "当前模型: $MODEL"
    
    # 檢查是否匹配配置
    if [ -f "data/config.json" ]; then
        CONFIG_MODEL=$(cat data/config.json | jq -r '.agents.main.model // "未配置"')
        if [ "$MODEL" = "$CONFIG_MODEL" ]; then
            log "配置匹配 ✅"
        else
            warn "配置不匹配"
            echo "  配置文件: $CONFIG_MODEL"
            echo "  運行时: $MODEL"
        fi
    fi
else
    error "无法检测模型"
fi

# 檢查 Skills
echo ""
info "檢查 Skills 狀態..."
echo ""

if docker logs openclaw_gateway 2>&1 | grep "Skills ready" | tail -1 | grep -q "✓"; then
    SKILLS_COUNT=$(docker logs openclaw_gateway 2>&1 | grep "Skills ready" | tail -1 | sed -n 's/.*✓ \([0-9]*\) Skills ready.*/\1/p')
    log "Skills: $SKILLS_COUNT 个已就绪"
else
    warn "Skills 狀態未知"
fi

# 檢查认证提供商
echo ""
info "檢查 AI 提供商..."
echo ""

if docker exec openclaw_gateway cat /root/.openclaw/agents/main/agent/auth-profiles.json 2>/dev/null | jq -e '.anthropic' > /dev/null 2>&1; then
    log "Anthropic (Claude) ✅"
fi

if docker exec openclaw_gateway cat /root/.openclaw/agents/main/agent/auth-profiles.json 2>/dev/null | jq -e '.google' > /dev/null 2>&1; then
    log "Google (Gemini) ✅"
fi

if docker exec openclaw_gateway cat /root/.openclaw/agents/main/agent/auth-profiles.json 2>/dev/null | jq -e '.openai' > /dev/null 2>&1; then
    log "OpenAI (GPT) ✅"
fi

# 檢查端口
echo ""
info "檢查服务端口..."
echo ""

if docker exec openclaw_gateway netstat -tln 2>/dev/null | grep -q ':18789'; then
    log "内部端口 18789 - 监听中"
fi

if docker exec openclaw_gateway netstat -tln 2>/dev/null | grep -q ':18790'; then
    log "外部端口 18790 - 监听中"
fi

# 总结
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  系统狀態总览${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
echo ""
echo "  OpenClaw Gateway: $GATEWAY_STATUS"
echo "  Traefik Proxy:    $TRAEFIK_STATUS"
echo "  Telegram Bot:     $TELEGRAM_STATUS"
echo ""

# 快速操作
echo ""
info "快速操作："
echo "  查看日志:    docker logs openclaw_gateway -f"
echo "  重启服务:    docker compose restart openclaw"
echo "  查看容器:    docker ps"
echo "  管理模型:    ./scripts/manage-providers.sh"
echo ""
