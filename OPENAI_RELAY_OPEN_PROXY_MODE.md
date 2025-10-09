# OpenAI Relay Server - Open Proxy Mode Implementation

## Overview

The OpenAI relay server has been converted from token-based authentication to **open proxy mode**, where the server uses its own OpenAI API key for all connections. This simplifies deployment and removes the need for ephemeral token generation via Edge Functions.

## Changes Made

### 1. Relay Server (`openai-relay-server/src/index.ts`)

**Key Changes:**
- Added required `OPENAI_API_KEY` environment variable
- Server validates API key on startup (exits if missing)
- Removed token extraction from client WebSocket subprotocols
- Server uses its own API key for all OpenAI connections
- Simplified `parseWebSocketAuth()` function to only extract model parameter

**Authentication Flow (Before):**
```
Client → Edge Function → Ephemeral Token → Relay → OpenAI
```

**Authentication Flow (After - Open Proxy):**
```
Client → Relay (uses OPENAI_API_KEY) → OpenAI
```

### 2. Frontend Composable (`src/views/MobileClient/components/AIAssistant/composables/useRealtimeConnection.ts`)

**Key Changes:**
- `getEphemeralToken()` function now returns dummy token (maintains API compatibility)
- `createWebSocket()` function simplified:
  - No longer sends authentication token in subprotocol
  - Only sends `['realtime']` subprotocol (not authentication protocols)
  - Requires `VITE_OPENAI_RELAY_URL` to be configured
- Removed complex token handling logic

**WebSocket Connection (Before):**
```typescript
new WebSocket(url, [
  'realtime',
  `openai-insecure-api-key.${ephemeralToken}`,
  'openai-beta.realtime-v1'
])
```

**WebSocket Connection (After - Open Proxy):**
```typescript
new WebSocket(url, ['realtime'])
```

### 3. Documentation Updates

**Updated Files:**
- `openai-relay-server/.env.example` - Added required `OPENAI_API_KEY`
- `openai-relay-server/README.md` - Comprehensive rewrite for open proxy mode
  - Added security warnings
  - Updated all code examples
  - Removed token authentication references
  - Added security best practices section

## Configuration

### Relay Server Environment Variables

**Required:**
```bash
OPENAI_API_KEY=sk-proj-your-openai-api-key-here  # REQUIRED
```

**Optional:**
```bash
PORT=8080
NODE_ENV=production
OPENAI_API_URL=wss://api.openai.com/v1/realtime
MAX_CONNECTIONS=100
HEARTBEAT_INTERVAL=30000
INACTIVITY_TIMEOUT=300000
ALLOWED_ORIGINS=https://app.cardy.com  # IMPORTANT: Set to specific domain in production
DEBUG=false
```

### Frontend Environment Variables

**Required:**
```bash
VITE_OPENAI_RELAY_URL=wss://your-relay-server.com
```

For local development:
```bash
VITE_OPENAI_RELAY_URL=ws://localhost:8080
```

## Security Implications

### ⚠️ CRITICAL SECURITY CONSIDERATIONS

**This is an OPEN PROXY - anyone who can connect will use your OpenAI API key.**

### Required Security Measures

1. **Network Security (REQUIRED):**
   - Deploy behind firewall or VPN
   - Use IP whitelisting
   - Consider API gateway with authentication

2. **CORS Restrictions (REQUIRED):**
   - Set `ALLOWED_ORIGINS` to specific domains
   - Never use `*` in production
   - Example: `ALLOWED_ORIGINS=https://app.cardy.com`

3. **TLS/SSL (REQUIRED):**
   - Use `wss://` (not `ws://`) in production
   - Configure SSL termination (Nginx, Cloudflare, etc.)

4. **Monitoring (REQUIRED):**
   - Monitor OpenAI API usage in dashboard
   - Set up billing alerts
   - Track connection patterns for anomalies

5. **Rate Limiting (RECOMMENDED):**
   - Add rate limiting per IP address
   - Set per-client connection limits
   - Implement request throttling

6. **Additional Authentication (RECOMMENDED):**
   - Add custom authentication middleware
   - Use API keys for client identification
   - Implement user-based quotas

## Deployment Guide

### 1. Development Setup

```bash
cd openai-relay-server

# Install dependencies
npm install

# Configure environment
cp .env.example .env
nano .env  # Add OPENAI_API_KEY=sk-proj-...

# Start development server
npm run dev
```

### 2. Production Deployment (Docker)

```bash
cd openai-relay-server

# Build image
docker build -t openai-realtime-relay:latest .

# Configure environment
nano .env  # Add production OPENAI_API_KEY and ALLOWED_ORIGINS

# Start with Docker Compose
docker-compose up -d

# Check health
curl http://localhost:8080/health
```

### 3. Frontend Configuration

```bash
# .env.production
VITE_OPENAI_RELAY_URL=wss://relay.yourdomain.com
```

## Testing

### Test Relay Server

```bash
# Health check
curl http://localhost:8080/health

# WebSocket connection (no token needed)
npm install -g wscat
wscat -c "ws://localhost:8080/realtime" --subprotocol "realtime"
```

### Test Frontend Connection

1. Start relay server: `cd openai-relay-server && npm run dev`
2. Configure frontend: `VITE_OPENAI_RELAY_URL=ws://localhost:8080`
3. Start frontend: `npm run dev`
4. Navigate to card with AI assistant
5. Test realtime voice conversation

## Edge Function Changes

### Obsolete Edge Function

The `openai-realtime-relay` Edge Function is now **obsolete** in open proxy mode:
- Previously generated ephemeral tokens for client authentication
- No longer needed since relay server uses its own API key
- Can be removed or kept for backward compatibility

## Migration Steps

If migrating from token-based to open proxy mode:

1. **Update relay server:**
   ```bash
   cd openai-relay-server
   git pull  # Get latest code
   nano .env  # Add OPENAI_API_KEY
   docker-compose restart
   ```

2. **Update frontend:**
   ```bash
   git pull  # Get latest code
   # No .env changes needed (VITE_OPENAI_RELAY_URL already configured)
   npm run build:production
   ```

3. **Verify security:**
   - Confirm `ALLOWED_ORIGINS` is set to specific domain (not `*`)
   - Verify SSL/TLS is enabled (`wss://`)
   - Check firewall rules and network security
   - Monitor OpenAI API usage

## Benefits of Open Proxy Mode

1. **Simplified Architecture:**
   - No Edge Function needed for token generation
   - Reduced latency (one less hop)
   - Fewer moving parts to maintain

2. **Easier Deployment:**
   - Single environment variable (`OPENAI_API_KEY`)
   - No Supabase dependency for relay server
   - Can deploy anywhere (AWS, DigitalOcean, Railway, etc.)

3. **Better Performance:**
   - Direct connection to relay (no token fetch)
   - Reduced connection time
   - Lower overhead

## Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| Unauthorized API usage | Set `ALLOWED_ORIGINS`, deploy behind firewall |
| Excessive API costs | Set up billing alerts, implement rate limiting |
| DDoS attacks | Use CDN/WAF, implement connection limits |
| Key exposure | Use environment variables, never commit to git |
| Regional access issues | Deploy in OpenAI-accessible region |

## Monitoring and Alerts

### OpenAI Dashboard Monitoring

1. **Daily Usage Check:**
   - Monitor token usage per day
   - Track costs and trends
   - Set billing alerts

2. **Rate Limit Monitoring:**
   - Watch for rate limit errors
   - Scale `MAX_CONNECTIONS` accordingly
   - Add client-side rate limiting

3. **Error Tracking:**
   - Monitor relay server logs
   - Track OpenAI API errors
   - Alert on error rate spikes

### Relay Server Monitoring

```bash
# Real-time stats
curl http://localhost:8080/stats

# Monitor logs
docker-compose logs -f openai-realtime-relay

# Health checks
watch -n 5 'curl -s http://localhost:8080/health | jq'
```

## Cost Optimization

With open proxy mode, all users share the same API key. Optimize costs:

1. **Use Cost-Effective Models:**
   - Default: `gpt-4o-mini-realtime-preview-2024-12-17` (~7x cheaper)
   - Full model only when needed

2. **Implement Connection Limits:**
   - Set `MAX_CONNECTIONS` based on expected usage
   - Add per-user connection limits

3. **Monitor and Alert:**
   - Set up OpenAI billing alerts
   - Track daily spending trends
   - Alert on unusual usage patterns

4. **Add Rate Limiting:**
   - Limit requests per IP
   - Implement user quotas
   - Throttle excessive usage

## Future Enhancements

Consider adding:

1. **Custom Authentication:**
   - JWT token validation
   - API key per client
   - User-based rate limiting

2. **Advanced Monitoring:**
   - Prometheus metrics
   - Grafana dashboards
   - Error tracking (Sentry)

3. **Load Balancing:**
   - Multiple relay instances
   - Round-robin distribution
   - Auto-scaling

4. **Caching:**
   - Response caching
   - Model warming
   - Connection pooling

## Troubleshooting

### Server Won't Start

**Error:** "OPENAI_API_KEY environment variable is required"
- **Solution:** Add `OPENAI_API_KEY` to `.env` file

### Client Can't Connect

**Error:** "VITE_OPENAI_RELAY_URL is not configured"
- **Solution:** Add relay URL to frontend `.env.local` or `.env.production`

### CORS Errors

**Error:** "Access to WebSocket blocked by CORS policy"
- **Solution:** Update `ALLOWED_ORIGINS` in relay server `.env`

### High API Costs

**Issue:** Unexpected OpenAI API charges
- **Solution:** 
  1. Check `ALLOWED_ORIGINS` is restrictive
  2. Add rate limiting
  3. Monitor connection logs for suspicious activity

## Summary

The relay server is now a **simple open proxy** that:
- ✅ Uses server-side OpenAI API key
- ✅ No client authentication required
- ✅ Simplified deployment and maintenance
- ⚠️ Requires proper network security
- ⚠️ Must be deployed with CORS restrictions
- ⚠️ Needs monitoring and billing alerts

**Trade-off:** Simpler architecture vs. increased security responsibility. Ensure proper security measures are in place before production deployment.

