FROM node:20-slim

WORKDIR /app

COPY package*.json ./
RUN npm ci --production

COPY build/ ./build/

ENV MCP_HTTP_HOST=0.0.0.0

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD node -e "const http=require('http');http.get('http://localhost:'+(process.env.PORT||8080)+'/health',(r)=>{process.exit(r.statusCode===200?0:1)}).on('error',()=>process.exit(1))"

CMD ["node", "build/index.js"]
