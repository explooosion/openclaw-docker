#!/bin/bash
# OpenClaw Skills 更新腳本
# 更新所有已安裝的 Skills

set -e

SKILLS_DIR="./skills-custom"

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== OpenClaw Skills 更新工具 ===${NC}"
echo ""

# 檢查目錄是否存在
if [ ! -d "$SKILLS_DIR" ]; then
    echo -e "${RED}✗ Skills 目錄不存在: $SKILLS_DIR${NC}"
    echo "請先使用 ./scripts/install-skill.sh 安裝 Skills"
    exit 1
fi

# 計數器
TOTAL=0
UPDATED=0
FAILED=0

# 遍歷所有 Skills
cd "$SKILLS_DIR"

for skill_dir in */; do
    # 移除尾部斜線
    skill=$(basename "$skill_dir")
    
    if [ ! -d "$skill_dir/.git" ]; then
        echo -e "${YELLOW}⊘ '$skill' 不是 Git repository，跳過${NC}"
        continue
    fi
    
    TOTAL=$((TOTAL + 1))
    echo -e "${BLUE}→ 更新 '$skill'...${NC}"
    
    cd "$skill_dir"
    
    # 檢查是否有未提交的更改
    if [ -n "$(git status --porcelain)" ]; then
        echo -e "${YELLOW}  ⚠ 有未提交的更改，跳過更新${NC}"
        cd ..
        continue
    fi
    
    # 獲取當前分支
    BRANCH=$(git rev-parse --abbrev-ref HEAD)
    
    # 拉取更新
    if git pull origin "$BRANCH" > /dev/null 2>&1; then
        # 檢查是否有實際更新
        if git diff --quiet HEAD@{1} HEAD 2>/dev/null; then
            echo -e "${GREEN}  ✓ 已是最新版本${NC}"
        else
            echo -e "${GREEN}  ✓ 更新成功${NC}"
            UPDATED=$((UPDATED + 1))
            
            # 顯示更新摘要
            echo "    變更："
            git log --oneline --pretty=format:"    - %s" HEAD@{1}..HEAD 2>/dev/null | head -3
        fi
    else
        echo -e "${RED}  ✗ 更新失敗${NC}"
        FAILED=$((FAILED + 1))
    fi
    
    cd ..
    echo ""
done

cd ..

# 顯示摘要
echo -e "${BLUE}=== 更新摘要 ===${NC}"
echo "總計: $TOTAL 個 Skills"
echo -e "${GREEN}更新: $UPDATED 個${NC}"
if [ $FAILED -gt 0 ]; then
    echo -e "${RED}失敗: $FAILED 個${NC}"
fi
echo ""

# 如果有更新，詢問是否重啟
if [ $UPDATED -gt 0 ]; then
    echo -e "${YELLOW}有 Skills 已更新${NC}"
    read -p "是否重啟 OpenClaw 容器以應用更新？(y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "重啟容器..."
        docker compose restart openclaw
        echo -e "${GREEN}✓ 容器重啟完成${NC}"
        echo ""
        echo "驗證更新:"
        echo "  docker exec openclaw_gateway openclaw skills list"
    else
        echo "請稍後手動重啟: docker compose restart openclaw"
    fi
else
    echo -e "${GREEN}所有 Skills 都是最新版本${NC}"
fi
