# Simplified OpenAI Relay Server
FROM node:20-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install production dependencies only
RUN npm ci --production

# Copy source
COPY src/index.ts ./src/
COPY tsconfig.json ./

# Build
RUN npm install typescript && \
    npx tsc src/index.ts --outDir dist --module commonjs --target es2020 && \
    npm uninstall typescript

# Run as non-root user
USER node

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD node -e "require('http').get('http://localhost:8080/health', (res) => { process.exit(res.statusCode === 200 ? 0 : 1); }).on('error', () => process.exit(1));"

# Start server
CMD ["node", "dist/index.js"]
