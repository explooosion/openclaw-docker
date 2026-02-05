#!/bin/sh
set -e

echo "Installing dependencies..."
apt-get update
apt-get install -y git socat net-tools curl wget jq python3 python3-pip

echo "Installing openclaw..."
npm uninstall -g openclaw 2>/dev/null || true
rm -rf /usr/local/lib/node_modules/openclaw 2>/dev/null || true
npm install -g openclaw@latest

echo "Installing useful Skills tools..."
# GitHub CLI (用於 github skill)
if ! command -v gh &> /dev/null; then
    echo "Installing GitHub CLI..."
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    apt-get update
    apt-get install -y gh
fi

# Google Workspace CLI (gog - 用於 Calendar, Gmail, Drive 等)
if ! command -v gog &> /dev/null; then
    echo "Installing gog CLI..."
    GOG_VERSION="0.9.0"
    ARCH=$(uname -m)
    if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
        GOG_ARCH="linux_arm64"
    else
        GOG_ARCH="linux_amd64"
    fi
    curl -fsSL "https://github.com/steipete/gogcli/releases/download/v${GOG_VERSION}/gogcli_${GOG_VERSION}_${GOG_ARCH}.tar.gz" -o /tmp/gog.tar.gz
    tar -xzf /tmp/gog.tar.gz -C /tmp
    mv /tmp/gog /usr/local/bin/gog
    chmod +x /usr/local/bin/gog
    rm -f /tmp/gog.tar.gz
    echo "✓ gog CLI installed"
fi

echo "Configuring multi-provider authentication..."
mkdir -p /root/.openclaw/agents/main/agent

# 官方推薦的 auth-profiles.json 格式
cat > /root/.openclaw/agents/main/agent/auth-profiles.json <<EOF
{
  "profiles": {
EOF

# 構建 profiles 對象
FIRST=true

# Anthropic (Claude)
if [ -n "$ANTHROPIC_API_KEY" ]; then
  if [ "$FIRST" = false ]; then
    echo "," >> /root/.openclaw/agents/main/agent/auth-profiles.json
  fi
  cat >> /root/.openclaw/agents/main/agent/auth-profiles.json <<EOF
    "anthropic:default": {
      "type": "api_key",
      "provider": "anthropic",
      "key": "$ANTHROPIC_API_KEY"
    }
EOF
  FIRST=false
  echo "  ✓ Anthropic Claude configured"
fi

# Google (Gemini)
if [ -n "$GEMINI_API_KEY" ]; then
  if [ "$FIRST" = false ]; then
    echo "," >> /root/.openclaw/agents/main/agent/auth-profiles.json
  fi
  cat >> /root/.openclaw/agents/main/agent/auth-profiles.json <<EOF
    "google:default": {
      "type": "api_key",
      "provider": "google",
      "key": "$GEMINI_API_KEY"
    }
EOF
  FIRST=false
  echo "  ✓ Google Gemini configured"
fi

# OpenAI (GPT)
if [ -n "$OPENAI_API_KEY" ]; then
  if [ "$FIRST" = false ]; then
    echo "," >> /root/.openclaw/agents/main/agent/auth-profiles.json
  fi
  cat >> /root/.openclaw/agents/main/agent/auth-profiles.json <<EOF
    "openai:default": {
      "type": "api_key",
      "provider": "openai",
      "key": "$OPENAI_API_KEY"
    }
EOF
  FIRST=false
  echo "  ✓ OpenAI GPT configured"
fi

# 結束 profiles 並添加 usageStats
cat >> /root/.openclaw/agents/main/agent/auth-profiles.json <<EOF
  },
  "usageStats": {}
}
EOF

if [ "$FIRST" = true ]; then
  echo "⚠ Warning: No AI provider API keys configured"
  echo "  Add API keys in .env file:"
  echo "    ANTHROPIC_API_KEY=sk-ant-..."
  echo "    GEMINI_API_KEY=AIza..."
  echo "    OPENAI_API_KEY=sk-..."
else
  echo "✓ Multi-provider authentication configured"
fi

# 確保 workspace 結構完整
echo "Setting up workspace structure..."
mkdir -p /root/.openclaw/workspace/skills/{bundled,managed,custom}
mkdir -p /root/.openclaw/agents/main/sessions

# 顯示配置狀態
echo ""
echo "Configuration Summary:"
echo "  Model: ${MODEL:-openai/gpt-3.5-turbo}"
echo "  Skills Directory: /root/.openclaw/workspace/skills"
echo "  Custom Skills: /root/.openclaw/skills/custom"
echo ""

echo "Configuring Skills environment variables..."
# GitHub CLI authentication
if [ -n "$GITHUB_TOKEN" ]; then
    echo "$GITHUB_TOKEN" | gh auth login --with-token 2>/dev/null || echo "GitHub CLI already authenticated"
    echo "✓ GitHub Token configured"
fi

# Google Workspace CLI authentication
if [ -n "$GOG_ACCOUNT" ] && [ -n "$GOG_KEYRING_PASSWORD" ]; then
    echo "✓ Google Workspace account configured: $GOG_ACCOUNT"
fi

echo "Checking Skills status..."
SKILLS_COUNT=$(find /root/.openclaw/workspace/skills -name "SKILL.md" 2>/dev/null | wc -l || echo 0)
CUSTOM_SKILLS=$(find /root/.openclaw/skills/custom -name "SKILL.md" 2>/dev/null | wc -l || echo 0)
TOTAL_SKILLS=$((SKILLS_COUNT + CUSTOM_SKILLS))
echo "✓ $TOTAL_SKILLS Skills ready ($CUSTOM_SKILLS custom)"

echo "Starting openclaw gateway in background..."
cd /root/.openclaw
openclaw gateway --verbose &
OPENCLAW_PID=$!

echo "Waiting for openclaw to be ready on port 18789..."
for i in $(seq 1 30); do
    if netstat -tln | grep -q ':18789 '; then
        echo "OpenClaw AI core is online."
        break
    fi
    echo "Still waiting for OpenClaw to bind... ($i/30)"
    sleep 2
done

echo "Starting socat proxy: 0.0.0.0:18790 -> 127.0.0.1:18789"
exec socat TCP-LISTEN:18790,fork,reuseaddr,bind=0.0.0.0 TCP:127.0.0.1:18789
