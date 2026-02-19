# Cloudflare Tunnel Setup Guide

This guide explains how to deploy Stoat using Cloudflare Tunnels for automatic SSL certificates and DNS configuration without exposing ports on your server.

## Table of Contents

- [What is Cloudflare Tunnel?](#what-is-cloudflare-tunnel)
- [Benefits](#benefits)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Detailed Setup](#detailed-setup)
- [Troubleshooting](#troubleshooting)
- [Managing Your Tunnel](#managing-your-tunnel)

## What is Cloudflare Tunnel?

Cloudflare Tunnel (formerly Argo Tunnel) creates a secure, outbound-only connection between your server and Cloudflare's network. This means:

- **No inbound ports needed** - Your server connects to Cloudflare, not the other way around
- **Automatic SSL/TLS** - Cloudflare handles all certificate management
- **DDoS protection** - Built-in Cloudflare protection
- **DNS management** - Automatic DNS configuration via Cloudflare

## Benefits

Compared to traditional Caddy setup:

| Feature | Caddy (Traditional) | Cloudflare Tunnel |
|---------|---------------------|-------------------|
| Port exposure | Requires 80, 443 open | No ports needed |
| SSL certificates | Let's Encrypt (automatic) | Cloudflare (automatic) |
| DDoS protection | Manual setup | Built-in |
| DNS management | Manual | Automatic |
| Firewall rules | Must allow HTTP/HTTPS | Only outbound |
| Setup complexity | Simple | Moderate |

**Use Cloudflare Tunnel when:**
- You want zero port exposure
- Your ISP blocks ports 80/443
- You want built-in DDoS protection
- You manage DNS through Cloudflare
- You want simpler firewall rules

**Use Caddy when:**
- You prefer simpler setup
- You don't use Cloudflare DNS
- You want full control over SSL
- You're okay with exposed ports

## Prerequisites

1. **Cloudflare Account** with your domain added
2. **Domain DNS** managed by Cloudflare (nameservers pointed to Cloudflare)
3. **Cloudflare API Token** with appropriate permissions
4. **cloudflared** binary (automatically installed by setup script)

## Quick Start

```bash
# 1. Update .env file
cp .env.example .env
# Edit .env and set:
#   - CLOUDFLARE_API_TOKEN (required)
#   - CLOUDFLARE_ACCOUNT_ID (required)
#   - CLOUDFLARE_ZONE_ID (required)
#   - STOAT_DOMAIN (your domain)

# 2. Run setup script
make cloudflare-setup
# or
./setup-cloudflare-tunnel.sh

# 3. Enable Cloudflare Tunnel in .env
# Set: USE_CLOUDFLARE_TUNNEL=true

# 4. Deploy
make deploy
# or deploy locally with Docker Compose:
docker compose -f compose.yml -f compose.cloudflare.yml up -d
```

## Detailed Setup

### Step 1: Create Cloudflare API Token

1. Log in to [Cloudflare Dashboard](https://dash.cloudflare.com)
2. Go to **My Profile** → **API Tokens**
3. Click **Create Token**
4. Choose **Edit Cloudflare Tunnel** template, or create custom with:
   - **Account** → **Cloudflare Tunnel** → **Edit**
   - **Zone** → **DNS** → **Edit**
   - **Zone** → **Zone** → **Read**
5. Copy the token and save it to `.env` as `CLOUDFLARE_API_TOKEN`

### Step 2: Get Account and Zone IDs

1. In Cloudflare Dashboard, select your domain
2. On the **Overview** page, scroll down to see:
   - **Account ID** (right sidebar) → Save as `CLOUDFLARE_ACCOUNT_ID`
   - **Zone ID** (right sidebar) → Save as `CLOUDFLARE_ZONE_ID`

### Step 3: Configure .env File

Edit your `.env` file:

```bash
# Enable Cloudflare Tunnel
USE_CLOUDFLARE_TUNNEL=true

# Cloudflare API Token
CLOUDFLARE_API_TOKEN=your_token_here

# Cloudflare Account ID
CLOUDFLARE_ACCOUNT_ID=your_account_id_here

# Cloudflare Zone ID  
CLOUDFLARE_ZONE_ID=your_zone_id_here

# Domain for Stoat
STOAT_DOMAIN=stoat.example.com

# Tunnel name (optional, defaults to stoat-tunnel)
CLOUDFLARE_TUNNEL_NAME=stoat-tunnel
```

### Step 4: Run Setup Script

The setup script will:
- Install cloudflared (if not present)
- Authenticate with Cloudflare
- Create or use existing tunnel
- Generate tunnel token
- Configure DNS automatically
- Update .env with tunnel credentials

```bash
./setup-cloudflare-tunnel.sh
```

**Output example:**
```
================================
Cloudflare Tunnel Setup for Stoat
================================

Configuration:
  Domain: stoat.example.com
  Tunnel Name: stoat-tunnel

✓ cloudflared installed
✓ Authenticating with Cloudflare
✓ Created tunnel: abc123def456
✓ Credentials saved
✓ Configuration created
✓ Tunnel token added to .env

================================
Setup Complete!
================================

Next steps:
1. Update USE_CLOUDFLARE_TUNNEL=true in .env
2. Deploy with: docker compose -f compose.yml -f compose.cloudflare.yml up -d
3. Or use Ansible with Cloudflare enabled
```

### Step 5: Deploy

**Option A: Using Make (recommended)**
```bash
make deploy
```

**Option B: Using Ansible manually**
```bash
source .env
cd ansible
ansible-playbook playbook.yml
```

**Option C: Using Docker Compose directly**
```bash
source .env
docker compose -f compose.yml -f compose.cloudflare.yml up -d
```

### Step 6: Verify Deployment

1. Check tunnel status:
   ```bash
   cloudflared tunnel info stoat-tunnel
   ```

2. Check Docker containers:
   ```bash
   docker compose ps
   ```

3. Access your domain:
   ```
   https://your-domain.com
   ```

## Troubleshooting

### Tunnel not connecting

Check tunnel logs:
```bash
docker compose logs cloudflared
```

Common issues:
- Invalid API token → Regenerate in Cloudflare Dashboard
- Tunnel token expired → Run setup script again
- DNS not configured → Check Cloudflare DNS records

### DNS not resolving

1. Check DNS records in Cloudflare Dashboard:
   - Should have CNAME record: `your-domain.com` → `tunnel-id.cfargotunnel.com`

2. Manually create if missing:
   ```bash
   cloudflared tunnel route dns stoat-tunnel your-domain.com
   ```

### Services not accessible

1. Verify tunnel configuration:
   ```bash
   cat cloudflared-config.yml
   ```

2. Check that services are running:
   ```bash
   docker compose ps
   ```

3. Test internal connectivity:
   ```bash
   docker compose exec cloudflared wget -O- http://web:5000
   ```

### Port conflicts

Cloudflare Tunnel doesn't need ports 80/443 exposed. If you're switching from Caddy:

1. Stop Caddy:
   ```bash
   docker compose stop caddy
   ```

2. Or use compose override to disable Caddy:
   ```yaml
   # compose.override.yml
   services:
     caddy:
       deploy:
         replicas: 0
   ```

## Managing Your Tunnel

### View tunnel information

```bash
make cloudflare-info
# or
cloudflared tunnel info stoat-tunnel
```

### List all tunnels

```bash
cloudflared tunnel list
```

### Update tunnel configuration

Edit `cloudflared-config.yml` and restart:
```bash
docker compose restart cloudflared
```

### Delete tunnel

```bash
make cloudflare-delete
# or
cloudflared tunnel delete stoat-tunnel
```

### Switch back to Caddy

1. Update `.env`:
   ```bash
   USE_CLOUDFLARE_TUNNEL=false
   ```

2. Redeploy:
   ```bash
   docker compose up -d
   ```

## Advanced Configuration

### Custom tunnel routes

Edit `cloudflared-config.yml.template` to customize routing:

```yaml
ingress:
  # Add custom subdomain
  - hostname: api.your-domain.com
    service: http://api:14702

  # Add IP filtering
  - hostname: admin.your-domain.com
    service: http://web:5000
    originRequest:
      access:
        required: true
        
  # Default catch-all (required)
  - service: http_status:404
```

### Multiple domains

You can route multiple domains through the same tunnel:

```yaml
ingress:
  - hostname: domain1.com
    service: http://web:5000
    
  - hostname: domain2.com
    service: http://web:5000
    
  - service: http_status:404
```

### Access policies

Integrate with Cloudflare Access for authentication:

```yaml
ingress:
  - hostname: your-domain.com
    service: http://web:5000
    originRequest:
      access:
        required: true
        teamName: your-team
        audTag: your-audit-tag
```

## Security Considerations

### Benefits

- **Zero inbound exposure** - No need to open ports 80/443
- **Built-in DDoS protection** - Cloudflare's network handles attacks
- **Automatic SSL** - Always encrypted, no cert management
- **IP hiding** - Your server's real IP is hidden

### Considerations

- **Cloudflare proxy** - All traffic goes through Cloudflare (privacy consideration)
- **Tunnel token** - Keep `CLOUDFLARE_TUNNEL_TOKEN` secure
- **API token** - Protect your Cloudflare API token

### Best practices

1. **Rotate tokens regularly**
2. **Use minimum required permissions** for API tokens
3. **Enable Cloudflare firewall rules** for additional protection
4. **Monitor tunnel logs** for suspicious activity
5. **Keep cloudflared updated** via Docker image updates

## Costs

Cloudflare Tunnel is **free** with any Cloudflare plan, including the free tier.

However, consider:
- **Bandwidth limits** on free tier (generous, but check usage)
- **Page Rules** limits if you need advanced routing
- **Cloudflare Access** requires paid plan for authentication

## Next Steps

- [Configure Cloudflare Access](https://developers.cloudflare.com/cloudflare-one/applications/) for authentication
- [Set up firewall rules](https://developers.cloudflare.com/firewall/) for additional security
- [Enable bot protection](https://developers.cloudflare.com/bots/) to block malicious traffic
- [Configure caching](https://developers.cloudflare.com/cache/) to improve performance

## Support

- **Cloudflare Tunnel docs**: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/
- **cloudflared GitHub**: https://github.com/cloudflare/cloudflared
- **Cloudflare Community**: https://community.cloudflare.com/

## Comparison: Caddy vs Cloudflare Tunnel

### Caddy Setup
```bash
# Exposes ports 80, 443
# Firewall must allow HTTP/HTTPS
# Let's Encrypt handles SSL
# Manual DNS configuration
# Server IP is public
```

### Cloudflare Tunnel Setup
```bash
# No ports exposed
# Firewall only needs outbound
# Cloudflare handles SSL
# Automatic DNS via API
# Server IP is hidden
```

Both are excellent choices - pick based on your needs!
