#!/usr/bin/env node

import { createServer as createHttpServer, IncomingMessage, ServerResponse } from "node:http";
import { randomUUID } from "node:crypto";
import { StreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/streamableHttp.js";
import { createServer } from "./server.js";

const PORT = parseInt(process.env.MCP_HTTP_PORT || process.env.PORT || "3001", 10);
const HOST = process.env.MCP_HTTP_HOST || "0.0.0.0";

const MAX_BODY_SIZE = 10 * 1024 * 1024; // 10 MB
const SESSION_TTL_MS = 30 * 60 * 1000; // 30 minutes
const CLEANUP_INTERVAL_MS = 5 * 60 * 1000; // 5 minutes

interface Session {
  transport: StreamableHTTPServerTransport;
  lastActivity: number;
}

// Track active sessions
const sessions = new Map<string, Session>();

// Periodic cleanup of stale sessions
const cleanupTimer = setInterval(() => {
  const now = Date.now();
  for (const [id, session] of sessions) {
    if (now - session.lastActivity > SESSION_TTL_MS) {
      session.transport.close().catch(() => {});
      sessions.delete(id);
      console.error(`Session expired and cleaned up: ${id}`);
    }
  }
}, CLEANUP_INTERVAL_MS);
cleanupTimer.unref();

const httpServer = createHttpServer(async (req: IncomingMessage, res: ServerResponse) => {
  try {
    const url = new URL(req.url || "/", `http://${req.headers.host || "localhost"}`);

    // Health check endpoint (Cloud Run health probes)
    if (url.pathname === "/health" && req.method === "GET") {
      res.writeHead(200, { "Content-Type": "application/json" });
      res.end(JSON.stringify({ status: "ok", sessions: sessions.size }));
      return;
    }

    // Only handle /mcp endpoint
    if (url.pathname !== "/mcp") {
      res.writeHead(404, { "Content-Type": "application/json" });
      res.end(JSON.stringify({ error: "Not found" }));
      return;
    }

    if (req.method === "POST") {
      const body = await parseJsonBody(req);
      if (body === null) {
        res.writeHead(400, { "Content-Type": "application/json" });
        res.end(JSON.stringify({ error: "Invalid JSON body" }));
        return;
      }

      const sessionId = req.headers["mcp-session-id"] as string | undefined;

      // Initialize request: create fresh server + transport
      if (isInitializeRequest(body)) {
        const server = createServer();
        const transport = new StreamableHTTPServerTransport({
          sessionIdGenerator: () => randomUUID(),
        });

        transport.onclose = () => {
          if (transport.sessionId) {
            sessions.delete(transport.sessionId);
            console.error(`Session closed: ${transport.sessionId}`);
          }
        };

        await server.connect(transport);
        await transport.handleRequest(req, res, body);

        if (transport.sessionId) {
          sessions.set(transport.sessionId, { transport, lastActivity: Date.now() });
          console.error(`Session initialized: ${transport.sessionId}`);
        }
        return;
      }

      // Non-initialize POST: route to existing session
      if (!sessionId || !sessions.has(sessionId)) {
        res.writeHead(400, { "Content-Type": "application/json" });
        res.end(JSON.stringify({ error: "Invalid or missing session. Send an initialize request first." }));
        return;
      }

      const session = sessions.get(sessionId)!;
      session.lastActivity = Date.now();
      await session.transport.handleRequest(req, res, body);
      return;
    }

    if (req.method === "GET") {
      const sessionId = req.headers["mcp-session-id"] as string | undefined;
      if (!sessionId || !sessions.has(sessionId)) {
        res.writeHead(400, { "Content-Type": "application/json" });
        res.end(JSON.stringify({ error: "Invalid or missing session." }));
        return;
      }
      const session = sessions.get(sessionId)!;
      session.lastActivity = Date.now();
      await session.transport.handleRequest(req, res);
      return;
    }

    if (req.method === "DELETE") {
      const sessionId = req.headers["mcp-session-id"] as string | undefined;
      if (!sessionId || !sessions.has(sessionId)) {
        res.writeHead(400, { "Content-Type": "application/json" });
        res.end(JSON.stringify({ error: "Invalid or missing session." }));
        return;
      }
      const session = sessions.get(sessionId)!;
      await session.transport.handleRequest(req, res);
      sessions.delete(sessionId);
      return;
    }

    res.writeHead(405, { "Content-Type": "application/json" });
    res.end(JSON.stringify({ error: "Method not allowed" }));
  } catch (err) {
    console.error("Unhandled error in request handler:", err);
    if (!res.headersSent) {
      res.writeHead(500, { "Content-Type": "application/json" });
      res.end(JSON.stringify({ error: "Internal server error" }));
    }
  }
});

httpServer.listen(PORT, HOST, () => {
  console.error(`FunTell MCP server started on http://${HOST}:${PORT}/mcp`);
});

// Graceful shutdown
function shutdown() {
  console.error("Shutting down...");
  clearInterval(cleanupTimer);

  // Close all active sessions
  const closePromises = Array.from(sessions.values()).map((s) =>
    s.transport.close().catch(() => {})
  );
  Promise.all(closePromises).finally(() => {
    httpServer.close(() => {
      console.error("Server stopped.");
      process.exit(0);
    });
    // Force exit if close takes too long
    setTimeout(() => process.exit(0), 5000).unref();
  });
}

process.on("SIGTERM", shutdown);
process.on("SIGINT", shutdown);

/**
 * Parse JSON body from IncomingMessage with size limit.
 */
function parseJsonBody(req: IncomingMessage): Promise<unknown | null> {
  return new Promise((resolve) => {
    const contentLength = parseInt(req.headers["content-length"] || "0", 10);
    if (contentLength > MAX_BODY_SIZE) {
      resolve(null);
      return;
    }

    let size = 0;
    const chunks: Buffer[] = [];
    req.on("data", (chunk: Buffer) => {
      size += chunk.length;
      if (size > MAX_BODY_SIZE) {
        req.destroy();
        resolve(null);
        return;
      }
      chunks.push(chunk);
    });
    req.on("end", () => {
      try {
        const raw = Buffer.concat(chunks).toString("utf-8");
        resolve(JSON.parse(raw));
      } catch {
        resolve(null);
      }
    });
    req.on("error", () => resolve(null));
  });
}

/**
 * Detect whether a JSON-RPC body contains an "initialize" method.
 */
function isInitializeRequest(body: unknown): boolean {
  if (Array.isArray(body)) {
    return body.some(
      (msg) => typeof msg === "object" && msg !== null && "method" in msg && msg.method === "initialize"
    );
  }
  return (
    typeof body === "object" &&
    body !== null &&
    "method" in body &&
    (body as Record<string, unknown>).method === "initialize"
  );
}
