#!/bin/bash
################################################################################
# Skills 持久化验证脚本
# 
# 用途: 验证 Skills 配置在容器重启后是否保留
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

CONTAINER_NAME="openclaw_gateway"
SKILLS_HOST_PATH="/Users/robby/Desktop/docker/openclaw-workspace/skills-custom"
SKILLS_CONTAINER_PATH="/root/.openclaw/skills/custom"

log() { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[⚠]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; }
info() { echo -e "${BLUE}[ℹ]${NC} $1"; }
section() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo ""
}

# 显示标题
clear
echo -e "${BLUE}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║     OpenClaw Skills 持久化验证工具                            ║
║     Version 1.0.0                                             ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

section "Step 1: 檢查宿主机 Skills"

info "宿主机 Skills 路径: $SKILLS_HOST_PATH"
echo ""

if [ ! -d "$SKILLS_HOST_PATH" ]; then
    error "宿主机 Skills 目录不存在"
    exit 1
fi

HOST_SKILLS=$(find "$SKILLS_HOST_PATH" -mindepth 1 -maxdepth 1 -type d ! -name ".*" | wc -l | tr -d ' ')
log "找到 $HOST_SKILLS 个自定义 Skills"

echo ""
echo "Skills 列表:"
find "$SKILLS_HOST_PATH" -mindepth 1 -maxdepth 1 -type d ! -name ".*" -exec basename {} \; | while read skill; do
    echo "  📦 $skill"
    if [ -f "$SKILLS_HOST_PATH/$skill/config.json" ]; then
        echo "     ✓ config.json"
    fi
    if [ -f "$SKILLS_HOST_PATH/$skill/SKILL.md" ]; then
        echo "     ✓ SKILL.md"
    fi
    echo ""
done

section "Step 2: 记录当前容器狀態"

if ! docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    error "容器 ${CONTAINER_NAME} 不存在"
    exit 1
fi

if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    warn "容器未運行，正在启动..."
    docker start "$CONTAINER_NAME"
    sleep 5
fi

log "容器運行中"
echo ""

info "檢查容器内 Skills 路径..."
CONTAINER_SKILLS_BEFORE=$(docker exec "$CONTAINER_NAME" sh -c "find $SKILLS_CONTAINER_PATH -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l" | tr -d ' ')
log "容器内找到 $CONTAINER_SKILLS_BEFORE 个 Skills"
echo ""

info "当前 Skills 列表:"
docker exec "$CONTAINER_NAME" sh -c "ls -1 $SKILLS_CONTAINER_PATH 2>/dev/null" | while read skill; do
    echo "  📦 $skill"
done
echo ""

info "OpenClaw 识别的 Skills:"
docker exec "$CONTAINER_NAME" openclaw skills list 2>&1 | grep -E "custom|Skills" | head -10

section "Step 3: 重启容器"

info "准备重启容器以测试持久化..."
read -p "按 Enter 继续重启，或 Ctrl+C 取消... " -r
echo ""

log "重启容器..."
docker restart "$CONTAINER_NAME"

info "等待容器启动..."
sleep 8

# 等待 OpenClaw 完全启动
info "等待 OpenClaw 服务启动..."
RETRY=0
MAX_RETRY=20
while [ $RETRY -lt $MAX_RETRY ]; do
    if docker exec "$CONTAINER_NAME" pgrep -f openclaw > /dev/null 2>&1; then
        log "OpenClaw 服务已启动"
        break
    fi
    echo -n "."
    sleep 1
    RETRY=$((RETRY + 1))
done
echo ""

if [ $RETRY -eq $MAX_RETRY ]; then
    error "OpenClaw 服务启动超时"
    exit 1
fi

section "Step 4: 验证持久化"

info "檢查容器内 Skills..."
CONTAINER_SKILLS_AFTER=$(docker exec "$CONTAINER_NAME" sh -c "find $SKILLS_CONTAINER_PATH -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l" | tr -d ' ')

echo ""
echo "持久化验证结果:"
echo "  宿主机 Skills: $HOST_SKILLS"
echo "  重启前容器 Skills: $CONTAINER_SKILLS_BEFORE"
echo "  重启后容器 Skills: $CONTAINER_SKILLS_AFTER"
echo ""

if [ "$CONTAINER_SKILLS_AFTER" -eq "$HOST_SKILLS" ] && [ "$CONTAINER_SKILLS_AFTER" -eq "$CONTAINER_SKILLS_BEFORE" ]; then
    log "✅ 持久化验证成功！Skills 数量一致"
else
    warn "⚠️ Skills 数量不一致"
fi

section "Step 5: 详细对比"

info "对比宿主机和容器内的 Skills..."
echo ""

ALL_MATCH=true

find "$SKILLS_HOST_PATH" -mindepth 1 -maxdepth 1 -type d ! -name ".*" -exec basename {} \; | while read skill; do
    if docker exec "$CONTAINER_NAME" test -d "$SKILLS_CONTAINER_PATH/$skill" 2>/dev/null; then
        log "✅ $skill - 存在"
        
        # 檢查关键文件
        if docker exec "$CONTAINER_NAME" test -f "$SKILLS_CONTAINER_PATH/$skill/config.json" 2>/dev/null; then
            echo "   ✓ config.json"
        else
            echo "   ✗ config.json 缺失"
        fi
        
        if docker exec "$CONTAINER_NAME" test -f "$SKILLS_CONTAINER_PATH/$skill/SKILL.md" 2>/dev/null; then
            echo "   ✓ SKILL.md"
        else
            echo "   ✗ SKILL.md 缺失"
        fi
    else
        error "❌ $skill - 不存在"
        ALL_MATCH=false
    fi
    echo ""
done

section "Step 6: OpenClaw 识别测试"

info "测试 OpenClaw 是否识别自定义 Skills..."
echo ""

CUSTOM_SKILLS_DETECTED=$(docker exec "$CONTAINER_NAME" openclaw skills list 2>&1 | grep -c "custom" || echo "0")

if [ "$CUSTOM_SKILLS_DETECTED" -gt 0 ]; then
    log "OpenClaw 识别到自定义 Skills"
    echo ""
    docker exec "$CONTAINER_NAME" openclaw skills list 2>&1 | grep -A 2 "custom"
else
    warn "OpenClaw 未识别到自定义 Skills"
    info "这可能是正常的，取决于 Skills 的配置方式"
fi

section "Step 7: Volume 映射验证"

info "檢查 Docker Volume 映射..."
echo ""

VOLUME_CONFIG=$(docker inspect "$CONTAINER_NAME" 2>/dev/null | grep -A 10 "Mounts" | grep -A 5 "skills")

if echo "$VOLUME_CONFIG" | grep -q "skills"; then
    log "Volume 映射配置正确"
    echo ""
    docker inspect "$CONTAINER_NAME" | jq '.[0].Mounts[] | select(.Destination | contains("skills"))' 2>/dev/null || \
    docker inspect "$CONTAINER_NAME" | grep -A 3 '"Destination.*skills"'
else
    warn "未找到 skills 相关的 Volume 映射"
fi

section "测试总结"

echo ""
echo "📊 验证结果摘要:"
echo ""
echo "  宿主机 Skills:     $HOST_SKILLS 个"
echo "  容器内 Skills:     $CONTAINER_SKILLS_AFTER 个"
echo "  OpenClaw 识别:     $CUSTOM_SKILLS_DETECTED 个"
echo ""

if [ "$CONTAINER_SKILLS_AFTER" -eq "$HOST_SKILLS" ] && [ "$CONTAINER_SKILLS_AFTER" -gt 0 ]; then
    log "✅ Skills 持久化配置正确"
    echo ""
    info "下一步:"
    echo "  1. 测试具体的 Skill 功能"
    echo "  2. 在 Telegram 中验证 Skills"
    echo "  3. 添加更多自定义 Skills"
    echo ""
    echo "测试命令:"
    echo "  ./scripts/test-skill.sh weather"
    echo "  ./scripts/test-skill.sh qrcode"
    exit 0
else
    error "❌ Skills 持久化可能存在问题"
    echo ""
    info "排查建议:"
    echo "  1. 檢查 docker-compose.yml 中的 volumes 配置"
    echo "  2. 确认 skills-custom 目录权限"
    echo "  3. 查看容器日志: docker logs openclaw_gateway"
    echo "  4. 手动檢查映射: docker exec openclaw_gateway ls -la /root/.openclaw/skills/"
    exit 1
fi
