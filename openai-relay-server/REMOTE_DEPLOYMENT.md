# Remote Server Deployment Guide

## Quick Deployment Steps

### 1. SSH into the remote server
```bash
ssh user@136.114.213.182
```

### 2. Navigate to the relay server directory
```bash
cd ~/Cardy/openai-relay-server
```

### 3. Pull the latest changes
```bash
git pull origin main
```

### 4. Rebuild the Docker image
```bash
sudo docker-compose down
sudo docker-compose build --no-cache
sudo docker-compose up -d
```

### 5. Check the logs
```bash
sudo docker-compose logs -f
```

## Alternative: Manual Build and Deploy

If Docker is not being used:

```bash
# Install dependencies
npm install

# Build the TypeScript code
npm run build

# Restart the service (using pm2 or systemd)
pm2 restart openai-relay
# OR
sudo systemctl restart openai-relay
```

## Testing the Deployment

After deployment, test the endpoints:

```bash
# Health check
curl http://136.114.213.182:8080/health

# Test API key (new endpoint)
curl http://136.114.213.182:8080/test-api-key

# Check stats
curl http://136.114.213.182:8080/stats
```

## Troubleshooting

### If OpenAI returns server errors:

1. **Check API Key**: Ensure the API key has access to realtime models
   ```bash
   curl http://136.114.213.182:8080/test-api-key
   ```

2. **Verify Model Name**: The model should be `gpt-realtime-mini-2025-10-06`

3. **Check Session Configuration**: The session.update payload should match OpenAI's GA format:
   ```json
   {
     "modalities": ["text", "audio"],
     "instructions": "...",
     "voice": "alloy",
     "input_audio_format": "pcm16",
     "output_audio_format": "pcm16",
     "turn_detection": {
       "type": "server_vad",
       "threshold": 0.5,
       "prefix_padding_ms": 300,
       "silence_duration_ms": 500
     },
     "temperature": 0.8,
     "max_output_tokens": "inf"
   }
   ```

4. **Check Environment Variables**:
   ```bash
   # In the .env file
   OPENAI_API_KEY=sk-...
   OPENAI_REALTIME_MODEL=gpt-realtime-mini-2025-10-06
   ```

## Current Issues and Solutions

### Issue: OpenAI Server Errors
The OpenAI API is returning server errors after receiving session.update. This could be due to:

1. **Invalid session configuration format** - We've updated to match GA API format
2. **API key doesn't have realtime access** - Use test-api-key endpoint to verify
3. **Model name is incorrect** - Should be `gpt-realtime-mini-2025-10-06`

### Recent Changes Made:
- Updated session configuration to GA API format
- Added test-api-key endpoint to verify API access
- Simplified session configuration to minimal working set
- Added detailed logging for session.update payload
