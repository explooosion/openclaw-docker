#!/bin/bash
################################################################################
# 多提供商模型管理脚本
# 
# 用途: 管理和切换 OpenClaw 的 AI 模型提供商
################################################################################

set -e

# 颜色定义
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
section() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
    echo ""
}

# 显示帮助
show_help() {
    cat << EOF
用法: $0 [命令]

命令:
    list            列出所有可用的模型提供商和模型
    status          显示当前配置狀態
    switch <model>  切换到指定模型
    providers       显示已配置的提供商
    test            测试当前模型

示例:
    $0 list
    $0 switch anthropic/claude-3-5-haiku-20241022
    $0 switch google/gemini-2.0-flash-exp
    $0 status

EOF
}

# 列出所有可用模型
list_models() {
    section "可用模型列表"
    
    echo -e "${CYAN}Anthropic Claude:${NC}"
    echo "  anthropic/claude-3-5-haiku-20241022    ⚡ 快速、经济 💰"
    echo "  anthropic/claude-3-5-sonnet-20241022   ⚖️  平衡性能 💰💰"
    echo "  anthropic/claude-opus-4-5              🧠 最强性能 💰💰💰"
    echo ""
    
    echo -e "${CYAN}Google Gemini:${NC}"
    echo "  google/gemini-2.0-flash-exp            ⚡ 快速、免费 🆓"
    echo "  google/gemini-1.5-pro                  🎯 高性能 🆓"
    echo "  google/gemini-1.5-flash                ⚡ 快速响应 🆓"
    echo ""
    
    echo -e "${CYAN}OpenAI GPT:${NC}"
    echo "  openai/gpt-4o                          🎨 多模态 💰💰💰"
    echo "  openai/gpt-4-turbo                     🧠 高性能 💰💰💰"
    echo "  openai/gpt-3.5-turbo                   💰 经济型 💰"
    echo ""
}

# 显示当前狀態
show_status() {
    section "当前配置狀態"
    
    # 檢查配置文件
    if [ -f "data/config.json" ]; then
        CURRENT_MODEL=$(cat data/config.json | jq -r '.agents.main.model // "未配置"')
        log "配置文件: data/config.json"
        info "当前模型: $CURRENT_MODEL"
    else
        warn "配置文件不存在"
    fi
    
    echo ""
    
    # 檢查容器内配置
    if docker ps --format '{{.Names}}' | grep -q "openclaw_gateway"; then
        CONTAINER_MODEL=$(docker exec openclaw_gateway cat /root/.openclaw/config.json 2>/dev/null | jq -r '.agents.main.model // "未配置"')
        log "容器配置: $CONTAINER_MODEL"
        
        # 檢查運行时模型
        RUNTIME_MODEL=$(docker logs openclaw_gateway 2>&1 | grep "agent model" | tail -1 | sed -n 's/.*agent model: \(.*\)/\1/p' | tr -d ' \n')
        if [ -n "$RUNTIME_MODEL" ]; then
            log "運行时模型: $RUNTIME_MODEL"
        fi
    else
        warn "OpenClaw 容器未運行"
    fi
    
    echo ""
}

# 显示已配置的提供商
show_providers() {
    section "已配置的提供商"
    
    # 檢查环境变量
    if [ -f ".env" ]; then
        info "檢查 API Keys..."
        echo ""
        
        if grep -q "ANTHROPIC_API_KEY=sk-ant" .env 2>/dev/null; then
            log "✓ Anthropic (Claude)"
            ANTHROPIC_KEY=$(grep "ANTHROPIC_API_KEY" .env | cut -d'=' -f2 | cut -c1-20)
            echo "  Key: ${ANTHROPIC_KEY}..."
        else
            warn "✗ Anthropic 未配置"
        fi
        
        if grep -q "GEMINI_API_KEY=AIza" .env 2>/dev/null; then
            log "✓ Google (Gemini)"
            GEMINI_KEY=$(grep "GEMINI_API_KEY" .env | cut -d'=' -f2 | cut -c1-20)
            echo "  Key: ${GEMINI_KEY}..."
        else
            warn "✗ Google 未配置"
        fi
        
        if grep -q "OPENAI_API_KEY=sk-" .env 2>/dev/null; then
            log "✓ OpenAI (GPT)"
            OPENAI_KEY=$(grep "OPENAI_API_KEY" .env | cut -d'=' -f2 | cut -c1-20)
            echo "  Key: ${OPENAI_KEY}..."
        else
            warn "✗ OpenAI 未配置"
        fi
    else
        error ".env 文件不存在"
    fi
    
    echo ""
    
    # 檢查容器内认证
    if docker ps --format '{{.Names}}' | grep -q "openclaw_gateway"; then
        info "容器内认证配置:"
        docker exec openclaw_gateway cat /root/.openclaw/agents/main/agent/auth-profiles.json 2>/dev/null | jq 'keys' || warn "无法读取认证配置"
    fi
    
    echo ""
}

# 切换模型
switch_model() {
    local new_model=$1
    
    if [ -z "$new_model" ]; then
        error "请指定模型名称"
        echo "示例: $0 switch anthropic/claude-3-5-haiku-20241022"
        exit 1
    fi
    
    section "切换模型: $new_model"
    
    # 确定提供商
    local provider=""
    local provider_key=""
    
    if [[ $new_model == anthropic/* ]]; then
        provider="anthropic"
        provider_key="ANTHROPIC_API_KEY"
    elif [[ $new_model == google/* ]]; then
        provider="google"
        provider_key="GEMINI_API_KEY"
    elif [[ $new_model == openai/* ]]; then
        provider="openai"
        provider_key="OPENAI_API_KEY"
    else
        error "未知的提供商格式"
        exit 1
    fi
    
    # 檢查 API Key 是否配置
    if ! grep -q "${provider_key}=" .env 2>/dev/null || grep -q "${provider_key}=$" .env 2>/dev/null; then
        error "未配置 ${provider_key}"
        echo "请在 .env 文件中添加:"
        echo "  ${provider_key}=your_key_here"
        exit 1
    fi
    
    # 更新配置文件
    info "更新配置文件..."
    
    cat > data/config.json << EOF
{
  "gateway": {
    "mode": "local",
    "bind": "loopback",
    "trustedProxies": ["127.0.0.1", "0.0.0.0/0", "::/0"]
  },
  "agents": {
    "main": {
      "model": "$new_model",
      "authProfiles": {
        "$provider": {
          "apiKey": "\${${provider_key}}"
        }
      }
    }
  }
}
EOF
    
    log "配置文件已更新"
    
    # 复制到容器
    info "应用配置到容器..."
    docker cp data/config.json openclaw_gateway:/root/.openclaw/config.json
    
    # 清理旧的会话配置
    info "清理旧会话..."
    docker exec openclaw_gateway rm -rf /root/.openclaw/agents/main/sessions/* 2>/dev/null || true
    
    # 重启容器
    info "重启 OpenClaw..."
    docker compose restart openclaw
    
    log "模型切换完成！"
    echo ""
    info "等待 30 秒让服务完全启动..."
    sleep 30
    
    # 验证
    section "验证新配置"
    show_status
}

# 测试当前模型
test_model() {
    section "测试当前模型"
    
    if ! docker ps --format '{{.Names}}' | grep -q "openclaw_gateway"; then
        error "OpenClaw 容器未運行"
        exit 1
    fi
    
    info "在 Telegram 测试:"
    echo "  向 @openclaw_robby570_bot 发送："
    echo "  '你现在使用什么模型？'"
    echo ""
    
    info "查看日志:"
    docker logs openclaw_gateway 2>&1 | grep "agent model" | tail -1
    
    echo ""
}

# 主程序
case "${1:-}" in
    list)
        list_models
        ;;
    status)
        show_status
        ;;
    providers)
        show_providers
        ;;
    switch)
        switch_model "$2"
        ;;
    test)
        test_model
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        clear
        echo -e "${CYAN}"
        cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║     OpenClaw 多提供商管理工具                                 ║
║     Multi-Provider Model Manager                              ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
        echo -e "${NC}"
        
        show_help
        echo ""
        info "当前狀態:"
        show_status
        
        echo ""
        info "快速命令:"
        echo "  列出模型:    $0 list"
        echo "  查看狀態:    $0 status"
        echo "  切换模型:    $0 switch <model>"
        echo ""
        ;;
esac
