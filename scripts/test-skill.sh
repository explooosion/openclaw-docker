#!/bin/bash
################################################################################
# Skills 测试脚本
# 
# 用途: 验证 OpenClaw Skills 是否正确安装和配置
# 作者: OpenClaw Team
# 版本: 1.0.0
################################################################################

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 配置
SKILLS_DIR="./skills-custom"
CONTAINER_NAME="openclaw_gateway"

# 使用说明
show_usage() {
    cat << EOF
用法: $0 [选项] <skill-name>

选项:
    -v, --verbose       显示详细输出
    -h, --help          显示此帮助信息

参数:
    skill-name          要测试的 Skill 名称

示例:
    $0 gemini           # 测试 gemini Skill
    $0 -v weather       # 详细模式测试 weather Skill
    $0 --list           # 列出所有可用 Skills

EOF
}

# 日志函数
log() {
    echo -e "${GREEN}[✓]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

error() {
    echo -e "${RED}[✗]${NC} $1"
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

# 檢查 Docker 容器
check_container() {
    section "檢查 OpenClaw 容器"
    
    if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        error "OpenClaw 容器未運行"
        info "请启动容器: docker compose up -d"
        return 1
    fi
    log "OpenClaw 容器運行中"
    
    return 0
}

# 列出所有 Skills
list_skills() {
    section "可用 Skills 列表"
    
    info "查询 OpenClaw Skills..."
    docker exec "$CONTAINER_NAME" openclaw skills list
    
    return 0
}

# 测试指定 Skill
test_skill() {
    local skill_name=$1
    local verbose=$2
    
    section "测试 Skill: $skill_name"
    
    # 1. 檢查 Skill 是否存在
    info "檢查 Skill 狀態..."
    local skill_status=$(docker exec "$CONTAINER_NAME" openclaw skills list 2>&1 | grep -i "$skill_name" || echo "")
    
    if [ -z "$skill_status" ]; then
        error "未找到 Skill: $skill_name"
        warn "使用 --list 查看所有可用 Skills"
        return 1
    fi
    
    echo "$skill_status"
    echo ""
    
    # 2. 获取详细信息
    info "获取 Skill 详细信息..."
    docker exec "$CONTAINER_NAME" openclaw skills info "$skill_name" 2>&1 || true
    echo ""
    
    # 3. 檢查 Skill 狀態
    if echo "$skill_status" | grep -q "✓ ready"; then
        log "Skill 狀態: ✓ Ready"
    elif echo "$skill_status" | grep -q "✗ missing"; then
        warn "Skill 狀態: ✗ Missing"
        info "此 Skill 缺少必要的依赖或配置"
        return 2
    else
        warn "Skill 狀態: 未知"
    fi
    
    # 4. 檢查自定义 Skills 目录
    local custom_skill_path="$SKILLS_DIR/$skill_name"
    if [ -d "$custom_skill_path" ]; then
        log "找到自定义 Skill: $custom_skill_path"
        
        if [ "$verbose" = true ]; then
            info "Skill 文件:"
            ls -la "$custom_skill_path" | head -10
        fi
        
        # 檢查配置文件
        if [ -f "$custom_skill_path/config.json" ]; then
            log "配置文件: config.json 存在"
            if [ "$verbose" = true ]; then
                cat "$custom_skill_path/config.json" | jq . || cat "$custom_skill_path/config.json"
            fi
        else
            info "未找到 config.json (可能不需要)"
        fi
        
        # 檢查 SKILL.md
        if [ -f "$custom_skill_path/SKILL.md" ]; then
            log "说明文件: SKILL.md 存在"
            if [ "$verbose" = true ]; then
                echo "━━━━━━━━━━━━━━━━━━━━━━"
                head -20 "$custom_skill_path/SKILL.md"
                echo "━━━━━━━━━━━━━━━━━━━━━━"
            fi
        fi
    else
        info "未找到自定义 Skill 目录 (使用内建 Skill)"
    fi
    
    # 5. 测试建议
    section "测试建议"
    
    case "$skill_name" in
        gemini)
            info "Gemini Skill 测试方法:"
            echo "  在 Telegram 发送: 你好，请介绍一下自己"
            echo "  或在命令行: docker exec openclaw_gateway gemini '你好'"
            ;;
        github)
            info "GitHub Skill 测试方法:"
            echo "  在 Telegram 发送: 列出我的 GitHub repositories"
            echo "  需要: GitHub CLI (gh) 已认证"
            ;;
        gog)
            info "Google Workspace Skill 测试方法:"
            echo "  在 Telegram 发送: 我明天有什么行程？"
            echo "  需要: Google Calendar OAuth 配置"
            ;;
        weather)
            info "Weather Skill 测试方法:"
            echo "  在 Telegram 发送: 台北今天天气如何？"
            echo "  需要: OpenWeatherMap API Key"
            ;;
        *)
            info "通用测试方法:"
            echo "  在 Telegram Bot 中发送相关查询"
            echo "  查看 Bot 回应是否正常"
            ;;
    esac
    
    return 0
}

# 主程序
main() {
    local skill_name=""
    local verbose=false
    local list_mode=false
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -v|--verbose)
                verbose=true
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            --list)
                list_mode=true
                shift
                ;;
            *)
                skill_name="$1"
                shift
                ;;
        esac
    done
    
    # 显示标题
    clear
    echo -e "${BLUE}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║     OpenClaw Skills 测试工具                                  ║
║     Version 1.0.0                                             ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    # 檢查容器
    if ! check_container; then
        exit 1
    fi
    
    # 列出模式
    if [ "$list_mode" = true ]; then
        list_skills
        exit 0
    fi
    
    # 檢查参数
    if [ -z "$skill_name" ]; then
        error "请指定要测试的 Skill 名称"
        show_usage
        exit 1
    fi
    
    # 测试 Skill
    if test_skill "$skill_name" "$verbose"; then
        section "测试完成"
        log "Skill '$skill_name' 测试通过"
        echo ""
        info "下一步："
        echo "  1. 在 Telegram Bot 中进行实际测试"
        echo "  2. 查看日志: docker logs openclaw_gateway --tail 50"
        echo "  3. 如有问题，運行诊断: ./scripts/telegram-health-check.sh"
        exit 0
    else
        exit_code=$?
        section "测试失败"
        error "Skill '$skill_name' 测试未通过"
        
        if [ $exit_code -eq 2 ]; then
            echo ""
            info "可能的原因："
            echo "  1. 缺少必要的依赖（二进制文件）"
            echo "  2. 缺少 API Key 或配置"
            echo "  3. 需要安装额外的工具"
            echo ""
            info "解决方法："
            echo "  1. 查看 Skill 说明: docker exec openclaw_gateway openclaw skills info $skill_name"
            echo "  2. 安装所需依赖"
            echo "  3. 配置 API Keys（如需要）"
        fi
        
        exit 1
    fi
}

# 执行主程序
main "$@"
