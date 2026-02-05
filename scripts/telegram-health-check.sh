#!/bin/bash

################################################################################
# Telegram Bot Health Check & Auto-Fix Script
# 
# 用途: 自動診斷和修復 Telegram Bot 整合的常見問題
# 作者: OpenClaw Team
# 版本: 1.0.0
# 最後更新: 2026-02-05
################################################################################

set -e  # 遇到錯誤時退出

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置
WORKSPACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="$WORKSPACE_DIR/docker-compose.yml"
ENV_FILE="$WORKSPACE_DIR/.env"
LOG_FILE="$WORKSPACE_DIR/telegram-health-check.log"

# 日誌函數
log() {
    echo -e "${GREEN}[✓]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $1" >> "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[⚠]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARN] $1" >> "$LOG_FILE"
}

error() {
    echo -e "${RED}[✗]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $1" >> "$LOG_FILE"
}

info() {
    echo -e "${BLUE}[ℹ]${NC} $1"
}

section() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo ""
}

################################################################################
# 檢查項目
################################################################################

check_docker() {
    section "檢查 Docker 環境"
    
    if ! command -v docker &> /dev/null; then
        error "Docker 未安裝"
        return 1
    fi
    log "Docker 已安裝: $(docker --version)"
    
    if ! docker info &> /dev/null; then
        error "Docker daemon 未運行"
        return 1
    fi
    log "Docker daemon 運行中"
    
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        error "Docker Compose 未安裝"
        return 1
    fi
    log "Docker Compose 已安裝"
    
    return 0
}

check_env_file() {
    section "檢查環境變數配置"
    
    if [[ ! -f "$ENV_FILE" ]]; then
        error ".env 文件不存在"
        return 1
    fi
    log ".env 文件存在"
    
    # 檢查必要的環境變數
    source "$ENV_FILE"
    
    if [[ -z "$TELEGRAM_BOT_TOKEN" ]]; then
        error "TELEGRAM_BOT_TOKEN 未設定"
        warn "請在 .env 中設定: TELEGRAM_BOT_TOKEN=<your_bot_token>"
        return 1
    fi
    log "TELEGRAM_BOT_TOKEN 已設定"
    
    if [[ -z "$OPENCLAW_GATEWAY_TOKEN" ]]; then
        warn "OPENCLAW_GATEWAY_TOKEN 未設定（可選）"
    else
        log "OPENCLAW_GATEWAY_TOKEN 已設定"
    fi
    
    # 檢查 AI API Keys
    if [[ -z "$GEMINI_API_KEY" && -z "$ANTHROPIC_API_KEY" ]]; then
        warn "未設定任何 AI API Key（GEMINI_API_KEY 或 ANTHROPIC_API_KEY）"
    else
        log "AI API Key 已設定"
    fi
    
    return 0
}

check_containers() {
    section "檢查容器狀態"
    
    # 檢查 openclaw_gateway
    if ! docker ps --format '{{.Names}}' | grep -q "^openclaw_gateway$"; then
        error "openclaw_gateway 容器未運行"
        return 1
    fi
    
    container_status=$(docker inspect -f '{{.State.Status}}' openclaw_gateway)
    if [[ "$container_status" != "running" ]]; then
        error "openclaw_gateway 狀態異常: $container_status"
        return 1
    fi
    log "openclaw_gateway 運行中"
    
    # 檢查容器啟動時間
    started_at=$(docker inspect -f '{{.State.StartedAt}}' openclaw_gateway)
    log "容器啟動時間: $started_at"
    
    # 檢查是否有獨立的 telegram-bot 容器（應該不存在）
    if docker ps --format '{{.Names}}' | grep -q "telegram.bot"; then
        warn "偵測到獨立的 telegram-bot 容器，可能造成衝突"
        return 2  # 返回警告代碼
    fi
    
    return 0
}

check_telegram_provider() {
    section "檢查 Telegram Provider 狀態"
    
    # 檢查日誌中是否有 Telegram Provider 啟動訊息
    if docker logs openclaw_gateway 2>&1 | grep -q "telegram.*starting provider"; then
        log "Telegram Provider 已啟動"
        
        # 提取 Bot 用戶名
        bot_username=$(docker logs openclaw_gateway 2>&1 | grep "starting provider" | grep -oP '@\w+' | head -1)
        if [[ -n "$bot_username" ]]; then
            log "Bot 用戶名: $bot_username"
        fi
    else
        error "未找到 Telegram Provider 啟動訊息"
        warn "可能原因："
        warn "  1. TELEGRAM_BOT_TOKEN 未正確設定"
        warn "  2. OpenClaw 啟動失敗"
        warn "  3. Token 無效"
        return 1
    fi
    
    # 檢查是否有錯誤訊息
    if docker logs openclaw_gateway 2>&1 | grep -i "telegram.*error" | tail -5; then
        warn "發現 Telegram 相關錯誤訊息（見上方）"
    fi
    
    return 0
}

check_telegram_updates() {
    section "檢查 Telegram 訊息接收"
    
    # 檢查最近的 updates
    recent_updates=$(docker logs openclaw_gateway 2>&1 | grep "telegram.*update" | tail -5)
    
    if [[ -z "$recent_updates" ]]; then
        warn "未發現最近的 Telegram updates"
        info "請嘗試向 Bot 發送訊息，然後重新運行此腳本"
        return 2
    fi
    
    log "最近的 Telegram updates:"
    echo "$recent_updates" | while read -r line; do
        echo "  $line"
    done
    
    # 計算 update 數量
    update_count=$(echo "$recent_updates" | wc -l)
    log "最近 5 筆 updates 數量: $update_count"
    
    return 0
}

check_telegram_conflicts() {
    section "檢查 Telegram Bot 衝突"
    
    source "$ENV_FILE"
    
    # 檢查 webhook 狀態
    info "檢查 webhook 狀態..."
    webhook_info=$(curl -s "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getWebhookInfo")
    
    webhook_url=$(echo "$webhook_info" | grep -oP '"url":"[^"]*"' | cut -d'"' -f4)
    
    if [[ -n "$webhook_url" ]]; then
        warn "偵測到已設定的 webhook: $webhook_url"
        warn "這可能與 Long Polling 模式衝突"
        return 1
    else
        log "未設定 webhook（正確，使用 Long Polling）"
    fi
    
    # 檢查是否有 409 Conflict 錯誤
    if docker logs openclaw_gateway 2>&1 | grep -q "409 Conflict"; then
        error "偵測到 409 Conflict 錯誤（多個 Bot 實例衝突）"
        return 1
    fi
    
    return 0
}

check_network_connectivity() {
    section "檢查網路連接"
    
    # 檢查容器網路
    network_name=$(docker inspect openclaw_gateway | grep -oP '"NetworkMode": "\K[^"]+')
    log "容器網路: $network_name"
    
    # 檢查端口綁定
    port_bindings=$(docker port openclaw_gateway 2>&1 || echo "無端口映射")
    log "端口映射: $port_bindings"
    
    # 測試 Telegram API 連接（從容器內）
    info "測試 Telegram API 連接..."
    if docker exec openclaw_gateway sh -c "command -v curl > /dev/null && curl -s https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getMe | grep -q 'ok.:true'" 2>/dev/null; then
        log "Telegram API 連接正常"
    else
        warn "無法從容器內訪問 Telegram API（可能是網路問題）"
    fi
    
    return 0
}

################################################################################
# 自動修復功能
################################################################################

fix_webhook_conflict() {
    section "修復 Webhook 衝突"
    
    source "$ENV_FILE"
    
    info "正在清除 Telegram webhook..."
    result=$(curl -s "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/deleteWebhook?drop_pending_updates=true")
    
    if echo "$result" | grep -q '"ok":true'; then
        log "Webhook 已清除"
        return 0
    else
        error "清除 webhook 失敗: $result"
        return 1
    fi
}

fix_container_conflicts() {
    section "修復容器衝突"
    
    # 檢查是否有多個 telegram-bot 容器
    telegram_containers=$(docker ps -a --format '{{.Names}}' | grep telegram || true)
    
    if [[ -z "$telegram_containers" ]]; then
        log "未發現獨立的 telegram-bot 容器"
        return 0
    fi
    
    warn "發現以下 telegram 相關容器:"
    echo "$telegram_containers"
    
    read -p "是否停止並移除這些容器？[y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "$telegram_containers" | while read -r container; do
            info "停止容器: $container"
            docker stop "$container" || true
            info "移除容器: $container"
            docker rm "$container" || true
        done
        log "容器已清理"
        return 0
    else
        info "跳過容器清理"
        return 1
    fi
}

restart_openclaw() {
    section "重啟 OpenClaw Gateway"
    
    read -p "是否重啟 openclaw_gateway？[y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        info "正在重啟 openclaw_gateway..."
        docker compose restart openclaw
        
        info "等待服務啟動（預計 2-3 分鐘）..."
        sleep 30
        
        # 檢查啟動狀態
        for i in {1..6}; do
            if docker logs openclaw_gateway 2>&1 | grep -q "telegram.*starting provider"; then
                log "OpenClaw 已重啟，Telegram Provider 已啟動"
                return 0
            fi
            info "等待中... ($i/6)"
            sleep 20
        done
        
        warn "服務重啟完成，但未確認 Telegram Provider 啟動"
        return 1
    else
        info "跳過重啟"
        return 1
    fi
}

################################################################################
# 主流程
################################################################################

print_header() {
    clear
    echo -e "${BLUE}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║     Telegram Bot Health Check & Auto-Fix Tool                ║
║     OpenClaw Workspace                                        ║
║     Version 1.0.0                                             ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    info "日誌文件: $LOG_FILE"
    info "開始檢查時間: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
}

print_summary() {
    local total=$1
    local passed=$2
    local warnings=$3
    local failed=$4
    
    section "診斷摘要"
    
    echo "總檢查項目: $total"
    echo -e "✓ 通過: ${GREEN}$passed${NC}"
    echo -e "⚠ 警告: ${YELLOW}$warnings${NC}"
    echo -e "✗ 失敗: ${RED}$failed${NC}"
    echo ""
    
    if [[ $failed -eq 0 && $warnings -eq 0 ]]; then
        log "🎉 所有檢查項目通過！Telegram Bot 運行正常。"
    elif [[ $failed -eq 0 ]]; then
        warn "⚠️  有 $warnings 個警告項目，但基本功能正常。"
    else
        error "❌ 有 $failed 個檢查項目失敗，請檢查上方錯誤訊息。"
    fi
}

run_diagnostics() {
    local total=0
    local passed=0
    local warnings=0
    local failed=0
    
    # 執行所有檢查
    checks=(
        "check_docker"
        "check_env_file"
        "check_containers"
        "check_telegram_provider"
        "check_telegram_updates"
        "check_telegram_conflicts"
        "check_network_connectivity"
    )
    
    for check in "${checks[@]}"; do
        total=$((total + 1))
        
        if $check; then
            passed=$((passed + 1))
        else
            exit_code=$?
            if [[ $exit_code -eq 2 ]]; then
                warnings=$((warnings + 1))
            else
                failed=$((failed + 1))
            fi
        fi
    done
    
    print_summary $total $passed $warnings $failed
    
    return $failed
}

run_auto_fix() {
    section "自動修復模式"
    
    info "此模式將嘗試自動修復常見問題"
    echo ""
    
    # 修復 webhook 衝突
    if docker logs openclaw_gateway 2>&1 | grep -q "webhook"; then
        fix_webhook_conflict
    fi
    
    # 修復容器衝突
    if docker ps -a --format '{{.Names}}' | grep -q telegram; then
        fix_container_conflicts
    fi
    
    # 詢問是否重啟
    restart_openclaw
    
    section "自動修復完成"
    info "建議重新運行診斷以確認問題已解決"
}

show_help() {
    cat << EOF
用法: $0 [選項]

選項:
    -d, --diagnose      執行完整診斷（預設）
    -f, --fix           執行自動修復
    -h, --help          顯示此幫助訊息
    -v, --verbose       顯示詳細日誌

範例:
    $0                  # 執行診斷
    $0 --fix            # 執行自動修復
    $0 -d -v            # 執行詳細診斷

EOF
}

################################################################################
# 主程式入口
################################################################################

main() {
    print_header
    
    # 解析參數
    mode="diagnose"
    verbose=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--diagnose)
                mode="diagnose"
                shift
                ;;
            -f|--fix)
                mode="fix"
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            *)
                error "未知選項: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 執行對應模式
    case $mode in
        diagnose)
            if run_diagnostics; then
                exit 0
            else
                echo ""
                info "偵測到問題，是否執行自動修復？"
                read -p "執行自動修復？[y/N] " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    run_auto_fix
                fi
                exit 1
            fi
            ;;
        fix)
            run_auto_fix
            echo ""
            info "修復完成，執行診斷驗證..."
            sleep 2
            run_diagnostics
            ;;
    esac
}

# 執行主程式
main "$@"
