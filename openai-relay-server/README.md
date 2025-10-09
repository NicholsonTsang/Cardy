# OpenAI Realtime API Relay Server (Open Proxy Mode)

A WebSocket relay server that proxies connections between clients and the OpenAI Realtime API. This server operates in **open proxy mode**, using a server-side OpenAI API key to handle all authentication centrally.

## ⚠️ SECURITY NOTICE

**This relay server operates as an OPEN PROXY:**
- The server uses its own OpenAI API key for all connections
- Clients connect WITHOUT sending authentication tokens
- **Network-level security is CRITICAL** - deploy behind firewall/VPN or use CORS restrictions
- All connected clients share the same OpenAI API key and billing account
- Consider implementing additional authentication/rate limiting for production use

## 🎯 Purpose

This relay server solves the problem of OpenAI API access restrictions by:

- **Proxying WebSocket connections** between your frontend and OpenAI Realtime API
- **Bidirectional streaming** of audio data (input and output)
- **Transparent forwarding** of all messages without modification
- **Centralized API key management** on the server side
- **Automatic reconnection** and health monitoring
- **Production-ready** with Docker support and graceful shutdown

## 🏗️ Architecture

```
┌─────────────┐         WebSocket         ┌─────────────┐         WebSocket         ┌─────────────┐
│   Client    │ ────────────────────────> │    Relay    │ ────────────────────────> │   OpenAI    │
│  (Browser)  │ <──────────────────────── │   Server    │ <──────────────────────── │ Realtime API│
└─────────────┘                           └─────────────┘                           └─────────────┘
  (Your Region)                        (Accessible Region)                       (api.openai.com)
```

### Flow (Open Proxy Mode)

1. **Client connects** to relay server via WebSocket (`ws://relay-server:8080/realtime`)
2. **Relay server** uses its own OpenAI API key (no client authentication required)
3. **Relay creates** upstream connection to OpenAI Realtime API
4. **Messages flow bidirectionally** through the relay without modification
5. **Audio streams** (PCM16 base64) are forwarded in both directions
6. **Connection lifecycle** is synchronized between client and OpenAI

**Key Difference**: Clients no longer send authentication tokens - the relay handles all OpenAI authentication.

## 🚀 Quick Start

### Prerequisites

- Node.js 20+ or Docker
- OpenAI API access from deployment region
- Network access to `api.openai.com` from relay server

### Development Setup

1. **Install dependencies**:
```bash
cd openai-relay-server
npm install
```

2. **Configure environment**:
```bash
cp .env.example .env
# REQUIRED: Add your OpenAI API key to .env
nano .env  # Set OPENAI_API_KEY=sk-proj-...
```

**⚠️ CRITICAL**: The `OPENAI_API_KEY` environment variable is **required**. The server will not start without it.

3. **Start development server**:
```bash
npm run dev
```

The server will start on `http://localhost:8080` with hot-reload enabled.

### Production Deployment with Docker

1. **Build Docker image**:
```bash
docker build -t openai-realtime-relay:latest .
```

2. **Run with Docker Compose**:
```bash
docker-compose up -d
```

3. **Check health**:
```bash
curl http://localhost:8080/health
```

## 📦 Docker Deployment

### Using Docker Compose (Recommended)

The `docker-compose.yml` provides a production-ready setup with:
- Automatic restart on failure
- Health checks every 30 seconds
- Resource limits
- Log rotation
- Network isolation

```bash
# Start
docker-compose up -d

# View logs
docker-compose logs -f

# Stop
docker-compose down

# Restart
docker-compose restart
```

### Manual Docker Run

```bash
docker run -d \
  --name openai-realtime-relay \
  --restart unless-stopped \
  -p 8080:8080 \
  -e MAX_CONNECTIONS=100 \
  -e ALLOWED_ORIGINS=https://yourdomain.com \
  openai-realtime-relay:latest
```

### Docker Health Checks

The container includes built-in health checks:
- **Interval**: 30 seconds
- **Timeout**: 10 seconds
- **Retries**: 3
- **Start period**: 40 seconds

Docker will automatically restart the container if health checks fail.

## ⚙️ Configuration

### Environment Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `OPENAI_API_KEY` | - | **YES** | Your OpenAI API key (server exits if missing) |
| `PORT` | `8080` | No | Server listening port |
| `NODE_ENV` | `development` | No | Environment mode |
| `OPENAI_API_URL` | `wss://api.openai.com/v1/realtime` | No | OpenAI Realtime API endpoint |
| `MAX_CONNECTIONS` | `100` | No | Maximum concurrent connections |
| `HEARTBEAT_INTERVAL` | `30000` | No | WebSocket ping interval (ms) |
| `INACTIVITY_TIMEOUT` | `300000` | No | Connection timeout (ms) - 5 minutes |
| `ALLOWED_ORIGINS` | `*` | No | CORS allowed origins (comma-separated) |
| `DEBUG` | `false` | No | Enable debug logging |

### Production Configuration Example

```bash
# .env
OPENAI_API_KEY=sk-proj-your-production-key-here
NODE_ENV=production
PORT=8080
MAX_CONNECTIONS=200
ALLOWED_ORIGINS=https://yourdomain.com,https://app.yourdomain.com
HEARTBEAT_INTERVAL=30000
INACTIVITY_TIMEOUT=300000
DEBUG=false
```

**⚠️ SECURITY BEST PRACTICES:**
1. Never commit `.env` file to version control
2. Use separate API keys for development and production
3. Configure `ALLOWED_ORIGINS` to specific domains (not `*`)
4. Deploy behind firewall or VPN for additional security
5. Monitor API usage in OpenAI dashboard for anomalies

## 🔌 API Endpoints

### WebSocket Endpoint

**URL**: `ws://localhost:8080/realtime?model={model}`

**Query Parameters**:
- `model` (optional): OpenAI Realtime model to use
  - Default: `gpt-4o-mini-realtime-preview-2024-12-17` (cost-effective)
  - Alternative: `gpt-4o-realtime-preview-2024-12-17` (full model)

**Subprotocols**:
- `realtime` (required)

**Example Connection (Open Proxy Mode)**:
```javascript
// Simple connection - no authentication token needed
const ws = new WebSocket(
  'ws://localhost:8080/realtime?model=gpt-4o-mini-realtime-preview-2024-12-17',
  ['realtime']
)
```

**Note**: In open proxy mode, clients do NOT send authentication tokens. The relay server uses its own OpenAI API key.

### HTTP Endpoints

#### Health Check
```
GET /health
```

Response:
```json
{
  "status": "healthy",
  "uptime": 12345,
  "stats": {
    "totalConnections": 42,
    "activeConnections": 3,
    "messagesRelayed": 15678,
    "errors": 2
  },
  "timestamp": "2025-10-08T12:00:00.000Z"
}
```

#### Readiness Check
```
GET /ready
```

Returns `200 OK` if server can accept connections, `503` if at capacity.

#### Statistics
```
GET /stats
```

Response:
```json
{
  "totalConnections": 42,
  "activeConnections": 3,
  "messagesRelayed": 15678,
  "errors": 2,
  "maxConnections": 100,
  "uptime": 12345,
  "startTime": 1696780800000
}
```

## 🔧 Frontend Integration

### 1. Add Environment Variable

In your frontend's `.env.production`:
```bash
VITE_OPENAI_RELAY_URL=wss://your-relay-server.com
```

For local testing:
```bash
VITE_OPENAI_RELAY_URL=ws://localhost:8080
```

### 2. Update WebSocket Connection

The frontend connects to the relay server without authentication:

```typescript
// useRealtimeConnection.ts (open proxy mode)
function createWebSocket(model: string) {
  const relayUrl = import.meta.env.VITE_OPENAI_RELAY_URL
  
  if (!relayUrl) {
    throw new Error('VITE_OPENAI_RELAY_URL is required')
  }
  
  // Simple connection - no token authentication
  const wsUrl = `${relayUrl}/realtime?model=${encodeURIComponent(model)}`
  return new WebSocket(wsUrl, ['realtime'])
}
```

## 🧪 Testing

### Test Health Endpoint
```bash
curl http://localhost:8080/health
```

### Test WebSocket Connection
```bash
# Install wscat
npm install -g wscat

# Connect to relay (open proxy mode - no token needed)
wscat -c "ws://localhost:8080/realtime" \
  --subprotocol "realtime"

# Or specify full model explicitly
wscat -c "ws://localhost:8080/realtime?model=gpt-4o-realtime-preview-2024-12-17" \
  --subprotocol "realtime"
```

### Load Testing
```bash
# Install artillery
npm install -g artillery

# Run load test
artillery quick --count 50 --num 10 ws://localhost:8080/realtime
```

## 📊 Monitoring

### Docker Logs
```bash
# Follow logs
docker-compose logs -f openai-realtime-relay

# Last 100 lines
docker-compose logs --tail=100 openai-realtime-relay
```

### Health Monitoring
```bash
# Continuous health check
watch -n 5 'curl -s http://localhost:8080/health | jq'
```

### Prometheus Metrics (Future Enhancement)
Consider adding Prometheus metrics for production monitoring:
- Active connections gauge
- Message throughput counter
- Error rate counter
- Connection duration histogram

## 🚨 Error Handling

The relay server handles various error scenarios:

1. **Missing API Key**: Server exits immediately on startup if `OPENAI_API_KEY` is not set
2. **Capacity Reached**: Rejects new connections with code `1008`
3. **Upstream Errors**: Forwards error messages to client
4. **Connection Drops**: Automatically cleans up both ends
5. **Inactive Connections**: Closes after 5 minutes of inactivity

### Error Codes

| Code | Reason | Description |
|------|--------|-------------|
| `1000` | Normal closure | Clean shutdown |
| `1008` | Policy violation | Auth failure or capacity reached |
| `1011` | Internal error | Failed to connect to OpenAI |

## 🔒 Security Considerations

**⚠️ CRITICAL - Open Proxy Security:**

This server operates in **open proxy mode** - anyone who can connect will use your OpenAI API key. Implement multiple security layers:

1. **Network Security** (REQUIRED):
   - Deploy behind firewall or VPN
   - Use IP whitelisting
   - Consider API gateway with authentication

2. **CORS Restrictions** (REQUIRED):
   - Set `ALLOWED_ORIGINS` to specific domains (never `*` in production)
   - Example: `ALLOWED_ORIGINS=https://app.cardy.com`

3. **Additional Authentication** (RECOMMENDED):
   - Add custom authentication middleware
   - Use API keys for client identification
   - Implement rate limiting per client

4. **TLS/SSL** (REQUIRED):
   - Use `wss://` in production with SSL termination
   - Never expose unencrypted WebSocket endpoints

5. **Monitoring** (REQUIRED):
   - Monitor OpenAI API usage in dashboard
   - Set up billing alerts
   - Track connection patterns for anomalies

6. **Rate Limiting** (RECOMMENDED):
   - Add rate limiting per IP address
   - Set per-client connection limits
   - Implement request throttling

### Recommended Security Setup

```nginx
# Nginx SSL termination
server {
    listen 443 ssl http2;
    server_name relay.yourdomain.com;

    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    location / {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

## 🌐 Deployment Platforms

### AWS (ECS/Fargate)
1. Push image to ECR
2. Create ECS task definition
3. Deploy as Fargate service
4. Configure ALB for WebSocket support

### DigitalOcean
1. Push image to container registry
2. Create App Platform app
3. Configure health check path: `/health`
4. Enable WebSocket support

### Google Cloud Run
1. Push image to Artifact Registry
2. Deploy Cloud Run service
3. Enable WebSocket connections
4. Set max instances based on `MAX_CONNECTIONS`

### Railway
1. Connect GitHub repository
2. Configure environment variables
3. Railway auto-deploys on push
4. WebSocket support enabled by default

## 📈 Performance Tuning

### Optimize for High Throughput

```bash
# Increase file descriptors
ulimit -n 65536

# Docker resource limits
deploy:
  resources:
    limits:
      cpus: '2'
      memory: 1G
```

### Connection Pooling

Adjust `MAX_CONNECTIONS` based on:
- Server resources (CPU/Memory)
- Expected concurrent users
- OpenAI API rate limits

**Formula**: `MAX_CONNECTIONS = (Available_Memory_MB / 10) * CPU_Cores`

Example: 512MB RAM + 1 CPU = ~50 connections

## 🐛 Troubleshooting

### Connection Refused
```bash
# Check if server is running
docker ps | grep openai-realtime-relay

# Check logs
docker-compose logs openai-realtime-relay
```

### High Memory Usage
- Reduce `MAX_CONNECTIONS`
- Enable WebSocket compression
- Check for connection leaks in logs

### OpenAI Connection Errors
- Verify network access to `api.openai.com`
- Check firewall rules
- Validate ephemeral tokens

### Client Can't Connect
- Check `ALLOWED_ORIGINS` configuration
- Verify WebSocket subprotocols match
- Inspect browser console for errors

## 📚 Additional Resources

- [OpenAI Realtime API Documentation](https://platform.openai.com/docs/api-reference/realtime)
- [WebSocket Protocol RFC](https://datatracker.ietf.org/doc/html/rfc6455)
- [Docker Documentation](https://docs.docker.com/)
- [Node.js Best Practices](https://github.com/goldbergyoni/nodebestpractices)

## 🤝 Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

MIT License - see LICENSE file for details

## 💡 Support

For issues or questions:
- Check troubleshooting section
- Review Docker logs
- Open an issue on GitHub

---

**Built for CardStudio** - Enabling global access to AI-powered museum experiences

