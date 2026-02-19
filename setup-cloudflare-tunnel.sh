#!/usr/bin/env bash
# Script to setup Cloudflare Tunnel for Stoat deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}Cloudflare Tunnel Setup for Stoat${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

# Check if .env exists
if [ ! -f .env ]; then
    echo -e "${RED}ERROR: .env file not found!${NC}"
    echo "Please create .env from .env.example first"
    exit 1
fi

# Load environment variables
source .env

# Check if cloudflared is installed
if ! command -v cloudflared &> /dev/null; then
    echo -e "${YELLOW}cloudflared not found. Installing...${NC}"
    
    # Detect OS
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        if command -v apt-get &> /dev/null; then
            # Debian/Ubuntu
            curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
            sudo dpkg -i cloudflared.deb
            rm cloudflared.deb
        elif command -v yum &> /dev/null; then
            # CentOS/RHEL
            sudo yum install -y https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-x86_64.rpm
        else
            echo -e "${RED}Unsupported Linux distribution${NC}"
            exit 1
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        brew install cloudflared
    else
        echo -e "${RED}Unsupported operating system${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ cloudflared installed${NC}"
fi

# Check required environment variables
if [ -z "$CLOUDFLARE_API_TOKEN" ]; then
    echo -e "${RED}ERROR: CLOUDFLARE_API_TOKEN not set in .env${NC}"
    echo ""
    echo "To create an API token:"
    echo "1. Go to https://dash.cloudflare.com/profile/api-tokens"
    echo "2. Click 'Create Token'"
    echo "3. Use 'Edit Cloudflare Tunnel' template or create custom with:"
    echo "   - Account | Cloudflare Tunnel | Edit"
    echo "   - Zone | DNS | Edit"
    echo "4. Add the token to .env as CLOUDFLARE_API_TOKEN"
    exit 1
fi

if [ -z "$STOAT_DOMAIN" ]; then
    echo -e "${RED}ERROR: STOAT_DOMAIN not set in .env${NC}"
    exit 1
fi

TUNNEL_NAME="${CLOUDFLARE_TUNNEL_NAME:-stoat-tunnel}"

echo -e "${BLUE}Configuration:${NC}"
echo "  Domain: $STOAT_DOMAIN"
echo "  Tunnel Name: $TUNNEL_NAME"
echo ""

# Login to Cloudflare (if not already logged in)
echo -e "${YELLOW}Authenticating with Cloudflare...${NC}"
export CLOUDFLARE_API_TOKEN

# Check if tunnel already exists
echo -e "${YELLOW}Checking for existing tunnel...${NC}"
EXISTING_TUNNEL=$(cloudflared tunnel list --output json 2>/dev/null | jq -r ".[] | select(.name==\"$TUNNEL_NAME\") | .id" || echo "")

if [ -n "$EXISTING_TUNNEL" ]; then
    echo -e "${GREEN}✓ Found existing tunnel: $TUNNEL_NAME ($EXISTING_TUNNEL)${NC}"
    TUNNEL_ID="$EXISTING_TUNNEL"
else
    echo -e "${YELLOW}Creating new tunnel: $TUNNEL_NAME${NC}"
    TUNNEL_ID=$(cloudflared tunnel create $TUNNEL_NAME --output json | jq -r '.id')
    if [ -z "$TUNNEL_ID" ]; then
        echo -e "${RED}ERROR: Failed to create tunnel${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ Created tunnel: $TUNNEL_ID${NC}"
fi

# Get tunnel credentials
echo -e "${YELLOW}Getting tunnel credentials...${NC}"
CREDS_FILE="$HOME/.cloudflared/$TUNNEL_ID.json"
if [ ! -f "$CREDS_FILE" ]; then
    echo -e "${RED}ERROR: Credentials file not found at $CREDS_FILE${NC}"
    echo "This may happen if the tunnel was created elsewhere."
    echo "Please download the credentials manually or delete and recreate the tunnel."
    exit 1
fi

# Copy credentials to project directory
mkdir -p .cloudflared
cp "$CREDS_FILE" .cloudflared/credentials.json
echo -e "${GREEN}✓ Credentials saved${NC}"

# Create config file from template
echo -e "${YELLOW}Creating tunnel configuration...${NC}"
export CLOUDFLARE_TUNNEL_ID="$TUNNEL_ID"
envsubst < cloudflared-config.yml.template > cloudflared-config.yml
echo -e "${GREEN}✓ Configuration created${NC}"

# Configure DNS
echo -e "${YELLOW}Configuring DNS...${NC}"
cloudflared tunnel route dns $TUNNEL_ID $STOAT_DOMAIN 2>/dev/null || {
    echo -e "${YELLOW}Note: DNS route may already exist or couldn't be created automatically${NC}"
    echo "You may need to manually create a CNAME record:"
    echo "  Name: $STOAT_DOMAIN"
    echo "  Target: $TUNNEL_ID.cfargotunnel.com"
}

# Get tunnel token for Docker Compose
echo -e "${YELLOW}Generating tunnel token...${NC}"
TUNNEL_TOKEN=$(cloudflared tunnel token $TUNNEL_ID)

# Update .env file
if grep -q "CLOUDFLARE_TUNNEL_TOKEN=" .env; then
    # Update existing
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|CLOUDFLARE_TUNNEL_TOKEN=.*|CLOUDFLARE_TUNNEL_TOKEN=$TUNNEL_TOKEN|" .env
    else
        sed -i "s|CLOUDFLARE_TUNNEL_TOKEN=.*|CLOUDFLARE_TUNNEL_TOKEN=$TUNNEL_TOKEN|" .env
    fi
else
    # Add new
    echo "CLOUDFLARE_TUNNEL_TOKEN=$TUNNEL_TOKEN" >> .env
fi

if grep -q "CLOUDFLARE_TUNNEL_ID=" .env; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|CLOUDFLARE_TUNNEL_ID=.*|CLOUDFLARE_TUNNEL_ID=$TUNNEL_ID|" .env
    else
        sed -i "s|CLOUDFLARE_TUNNEL_ID=.*|CLOUDFLARE_TUNNEL_ID=$TUNNEL_ID|" .env
    fi
else
    echo "CLOUDFLARE_TUNNEL_ID=$TUNNEL_ID" >> .env
fi

echo -e "${GREEN}✓ Tunnel token added to .env${NC}"

echo ""
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. Update USE_CLOUDFLARE_TUNNEL=true in .env"
echo "2. Deploy with: ${GREEN}docker compose -f compose.yml -f compose.cloudflare.yml up -d${NC}"
echo "3. Or use Ansible with Cloudflare enabled"
echo ""
echo -e "${BLUE}Tunnel Information:${NC}"
echo "  ID: $TUNNEL_ID"
echo "  Name: $TUNNEL_NAME"
echo "  Domain: $STOAT_DOMAIN"
echo ""
echo -e "${YELLOW}Note: Your tunnel is now configured but not running yet.${NC}"
echo "Start it with Docker Compose or through Ansible deployment."
