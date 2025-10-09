# Simplified OpenAI Relay Server Deployment

## Overview

The simplified version removes all unnecessary complexity and focuses solely on relaying WebSocket connections between clients and OpenAI's Realtime API using server-side authentication.

## Key Simplifications

### What Was Removed:
- ❌ Complex connection tracking and statistics
- ❌ Heartbeat monitoring
- ❌ Inactivity timeouts
- ❌ Connection limits
- ❌ Complex error recovery
- ❌ Detailed logging modes
- ❌ Test endpoints
- ❌ Rate limiting
- ❌ Complex CORS handling

### What Remains (Core Only):
- ✅ WebSocket relay between client and OpenAI
- ✅ Server-side OpenAI authentication
- ✅ Basic health check endpoint
- ✅ Essential error logging
- ✅ Graceful shutdown

## File Comparison

| Original | Simplified | Reduction |
|----------|------------|-----------|
| `index.ts` (520 lines) | `index-simplified.ts` (195 lines) | **62% smaller** |
| Complex state management | Simple connection map | Much cleaner |
| 10+ configuration options | 4 essential configs | Easier setup |

## Deployment Options

### Option 1: Direct Node.js

```bash
# Build
npm run build:simple

# Run
npm run start:simple
```

### Option 2: Docker (Simplified)

```bash
# Build image
docker build -f Dockerfile.simple -t openai-relay-simple .

# Run container
docker run -d \
  --name openai-relay \
  -p 8080:8080 \
  -e OPENAI_API_KEY=sk-... \
  openai-relay-simple
```

### Option 3: Docker Compose

Create `docker-compose.simple.yml`:

```yaml
version: '3.8'

services:
  relay:
    build:
      context: .
      dockerfile: Dockerfile.simple
    ports:
      - "8080:8080"
    environment:
      - OPENAI_API_KEY=${OPENAI_API_KEY}
      - PORT=8080
    restart: unless-stopped
```

Run with:
```bash
docker-compose -f docker-compose.simple.yml up -d
```

## Environment Variables

Only 4 environment variables needed:

```bash
# Required
OPENAI_API_KEY=sk-...          # Your OpenAI API key

# Optional (with defaults)
PORT=8080                       # Server port (default: 8080)
OPENAI_API_URL=wss://...       # OpenAI WebSocket URL (default: wss://api.openai.com/v1/realtime)
ALLOWED_ORIGINS=*               # CORS origins (default: *)
```

## Testing

### 1. Health Check
```bash
curl http://localhost:8080/health
```

Expected response:
```json
{
  "status": "healthy",
  "connections": 0,
  "timestamp": "2024-01-01T00:00:00.000Z"
}
```

### 2. WebSocket Connection
```javascript
const ws = new WebSocket('ws://localhost:8080/realtime', ['realtime'])

ws.onopen = () => {
  console.log('Connected to relay')
}

ws.onmessage = (event) => {
  const data = JSON.parse(event.data)
  
  if (data.type === 'session.created') {
    // Send session configuration
    ws.send(JSON.stringify({
      type: 'session.update',
      session: {
        model: 'gpt-realtime-mini-2025-10-06',
        modalities: ['text', 'audio'],
        voice: 'alloy',
        input_audio_format: 'pcm16',
        output_audio_format: 'pcm16',
        turn_detection: { type: 'server_vad' }
      }
    }))
  }
}
```

## Production Deployment

### For Remote Server (e.g., 136.114.213.182)

1. **SSH into server:**
```bash
ssh user@136.114.213.182
```

2. **Clone/update repository:**
```bash
cd ~/Cardy/openai-relay-server
git pull origin main
```

3. **Build and deploy:**
```bash
# Using Docker
docker build -f Dockerfile.simple -t openai-relay-simple .
docker stop openai-relay && docker rm openai-relay
docker run -d \
  --name openai-relay \
  -p 8080:8080 \
  --restart unless-stopped \
  -e OPENAI_API_KEY=sk-... \
  openai-relay-simple

# OR using PM2
npm run build:simple
pm2 stop openai-relay
pm2 start dist/index-simplified.js --name openai-relay
pm2 save
```

4. **Verify deployment:**
```bash
# Check health
curl http://136.114.213.182:8080/health

# Check logs (Docker)
docker logs -f openai-relay

# Check logs (PM2)
pm2 logs openai-relay
```

## Troubleshooting

### Connection Issues

1. **Check API key:**
   - Ensure `OPENAI_API_KEY` is set correctly
   - Verify key has access to Realtime API

2. **Check logs:**
   ```bash
   docker logs openai-relay  # or pm2 logs
   ```

3. **Common errors:**
   - `OPENAI_API_KEY environment variable is required` - Set the API key
   - `OpenAI connection error` - Check API key and network
   - `Client disconnected` - Normal when client closes connection

### Performance

The simplified server is much more efficient:
- Lower memory usage (no complex state tracking)
- Faster startup time
- Less CPU overhead
- Cleaner logs for debugging

## Migration from Complex Version

1. Stop the current server
2. Deploy simplified version
3. Update client if needed (should work without changes)
4. Monitor logs for any issues

The simplified version is fully compatible with the simplified frontend components.
