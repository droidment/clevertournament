import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import fetch from "node-fetch";

const projectRef = process.env.SUPABASE_PROJECT;
const pat = process.env.SUPABASE_PAT;

if (!projectRef || !pat) {
  console.error("Missing SUPABASE_PROJECT or SUPABASE_PAT env vars");
  process.exit(1);
}

const server = new Server({
  name: "supabase-sql",
  version: "0.1.0",
});

server.tool(
  {
    name: "exec_sql",
    description: "Execute SQL against Supabase SQL API for the configured project.",
    inputSchema: {
      type: "object",
      properties: {
        query: { type: "string", description: "SQL query or multi-statement script" },
      },
      required: ["query"],
    },
  },
  async ({ query }) => {
    const url = `https://api.supabase.com/v1/projects/${projectRef}/database/query`;
    const res = await fetch(url, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${pat}`,
        apikey: pat,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ query }),
    });
    const text = await res.text();
    if (!res.ok) {
      throw new Error(`SQL API error ${res.status}: ${text}`);
    }
    return {
      content: [
        {
          type: "text",
          text,
        },
      ],
    };
  }
);

server.start();
