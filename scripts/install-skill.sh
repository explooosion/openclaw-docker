#!/bin/bash
# OpenClaw Skills 快速安裝腳本
# 使用方式: ./install-skill.sh <skill-name> <github-repo-url>

set -e

SKILL_NAME=$1
SKILL_REPO=$2
SKILLS_DIR="./skills-custom"

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 使用說明
usage() {
    echo "OpenClaw Skills 安裝工具"
    echo ""
    echo "使用方式:"
    echo "  $0 <skill-name> <github-repo-url>"
    echo ""
    echo "範例:"
    echo "  $0 home-assistant https://github.com/VoltAgent/skill-home-assistant.git"
    echo "  $0 spotify https://github.com/VoltAgent/skill-spotify.git"
    echo ""
    echo "從 awesome-openclaw-skills 查找更多 Skills:"
    echo "  https://github.com/VoltAgent/awesome-openclaw-skills"
    exit 1
}

# 檢查參數
if [ -z "$SKILL_NAME" ] || [ -z "$SKILL_REPO" ]; then
    usage
fi

echo -e "${GREEN}=== OpenClaw Skills 安裝工具 ===${NC}"
echo ""

# 檢查 Docker 是否運行
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}✗ Docker 未運行，請先啟動 Docker${NC}"
    exit 1
fi

# 檢查 docker-compose.yml 是否存在
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${RED}✗ 未找到 docker-compose.yml，請在專案根目錄執行此腳本${NC}"
    exit 1
fi

# 創建 Skills 目錄
echo "1. 準備 Skills 目錄..."
mkdir -p "$SKILLS_DIR"

# 檢查 Skill 是否已安裝
if [ -d "$SKILLS_DIR/$SKILL_NAME" ]; then
    echo -e "${YELLOW}⚠ Skill '$SKILL_NAME' 已存在${NC}"
    read -p "是否要重新安裝？(y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "取消安裝"
        exit 0
    fi
    rm -rf "$SKILLS_DIR/$SKILL_NAME"
fi

# 克隆 Skill
echo "2. 下載 Skill '$SKILL_NAME'..."
if git clone "$SKILL_REPO" "$SKILLS_DIR/$SKILL_NAME" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Skill 下載完成${NC}"
else
    echo -e "${RED}✗ 下載失敗，請檢查 repository URL${NC}"
    exit 1
fi

# 檢查 Skill 結構
echo "3. 驗證 Skill 結構..."
SKILL_PATH="$SKILLS_DIR/$SKILL_NAME"

if [ -f "$SKILL_PATH/skill.json" ]; then
    echo -e "${GREEN}✓ 找到 skill.json${NC}"
    # 顯示 Skill 資訊
    if command -v jq > /dev/null 2>&1; then
        SKILL_DESC=$(jq -r '.description // "無描述"' "$SKILL_PATH/skill.json")
        SKILL_VERSION=$(jq -r '.version // "未知"' "$SKILL_PATH/skill.json")
        echo "  名稱: $SKILL_NAME"
        echo "  版本: $SKILL_VERSION"
        echo "  描述: $SKILL_DESC"
    fi
else
    echo -e "${YELLOW}⚠ 未找到 skill.json，這可能不是有效的 OpenClaw Skill${NC}"
fi

# 檢查依賴
echo "4. 檢查依賴..."
HAS_DEPS=false

if [ -f "$SKILL_PATH/requirements.txt" ]; then
    echo -e "${YELLOW}⚠ 發現 Python 依賴 (requirements.txt)${NC}"
    HAS_DEPS=true
fi

if [ -f "$SKILL_PATH/package.json" ]; then
    echo -e "${YELLOW}⚠ 發現 Node.js 依賴 (package.json)${NC}"
    HAS_DEPS=true
fi

# 檢查 docker-compose.yml 是否已配置 volume
echo "5. 檢查 Docker Compose 配置..."
if grep -q "skills-custom:/root/.openclaw/skills/custom" docker-compose.yml; then
    echo -e "${GREEN}✓ Skills volume 已配置${NC}"
else
    echo -e "${YELLOW}⚠ Skills volume 未配置${NC}"
    echo ""
    echo "請在 docker-compose.yml 的 openclaw 服務中添加："
    echo ""
    echo "  volumes:"
    echo "    - ./skills-custom:/root/.openclaw/skills/custom:ro"
    echo ""
    read -p "是否自動添加？(y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # 備份原文件
        cp docker-compose.yml docker-compose.yml.bak
        echo -e "${GREEN}✓ 已備份為 docker-compose.yml.bak${NC}"
        
        # 提示手動編輯
        echo -e "${YELLOW}請手動編輯 docker-compose.yml 添加 volume 配置${NC}"
        echo "然後重新執行此腳本"
        exit 0
    fi
fi

# 重啟容器
echo "6. 重啟 OpenClaw 容器..."
if docker compose restart openclaw > /dev/null 2>&1; then
    echo -e "${GREEN}✓ 容器重啟完成${NC}"
else
    echo -e "${RED}✗ 容器重啟失敗${NC}"
    exit 1
fi

# 等待容器啟動
echo "7. 等待容器啟動..."
sleep 5

# 安裝依賴（如果需要）
if [ "$HAS_DEPS" = true ]; then
    echo "8. 安裝 Skill 依賴..."
    
    if [ -f "$SKILL_PATH/requirements.txt" ]; then
        echo "  安裝 Python 依賴..."
        docker exec openclaw_gateway pip install -q -r "/root/.openclaw/skills/custom/$SKILL_NAME/requirements.txt" 2>&1 | grep -v "already satisfied" || true
        echo -e "${GREEN}✓ Python 依賴安裝完成${NC}"
    fi
    
    if [ -f "$SKILL_PATH/package.json" ]; then
        echo "  安裝 Node.js 依賴..."
        docker exec openclaw_gateway npm install --silent --prefix "/root/.openclaw/skills/custom/$SKILL_NAME" > /dev/null 2>&1
        echo -e "${GREEN}✓ Node.js 依賴安裝完成${NC}"
    fi
else
    echo "8. 無需安裝額外依賴"
fi

# 驗證安裝
echo "9. 驗證 Skill 安裝..."
sleep 2

if docker exec openclaw_gateway openclaw skills list 2>/dev/null | grep -q "$SKILL_NAME"; then
    echo -e "${GREEN}✓ Skill '$SKILL_NAME' 已成功安裝並載入${NC}"
else
    echo -e "${YELLOW}⚠ Skill 已安裝但未在列表中顯示${NC}"
    echo "  請檢查容器日誌："
    echo "  docker logs openclaw_gateway | grep -i skill"
fi

# 顯示配置說明
if [ -f "$SKILL_PATH/README.md" ]; then
    echo ""
    echo -e "${GREEN}=== 配置說明 ===${NC}"
    echo "Skill 可能需要額外配置，請查看："
    echo "  cat $SKILL_PATH/README.md"
    echo ""
fi

# 完成
echo ""
echo -e "${GREEN}=== 安裝完成 ===${NC}"
echo ""
echo "下一步："
echo "  1. 查看 Skills 列表: docker exec openclaw_gateway openclaw skills list"
echo "  2. 配置 Skill（如需要）: 編輯 data/agents/main/skills/$SKILL_NAME/config.json"
echo "  3. 測試 Skill: docker exec openclaw_gateway openclaw agent --local --agent main -m \"測試 $SKILL_NAME\""
echo ""
echo "更多 Skills: https://github.com/VoltAgent/awesome-openclaw-skills"
