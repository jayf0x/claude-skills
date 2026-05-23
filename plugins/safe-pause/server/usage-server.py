#!/usr/bin/env python3
"""
Local HTTP bridge: receives usage data POSTed by the Claude Usage Monitor extension
and writes it to ~/.claude/safeclaude/usage.json so the Claude Code hook can read it.

GET  /usage  — return current usage JSON
POST /usage  — accept usage payload from extension, write to disk
"""

import json
import os
import signal
import sys
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path

PORT = int(os.environ.get("CLAUDE_USAGE_PORT", "2999"))
USAGE_FILE = Path.home() / ".claude" / "safeclaude" / "usage.json"


class Handler(BaseHTTPRequestHandler):
    def do_OPTIONS(self):
        self._send_cors_headers()
        self.send_response(204)
        self.end_headers()

    def do_GET(self):
        if self.path != "/usage":
            self.send_response(404)
            self.end_headers()
            return
        if USAGE_FILE.exists():
            data = USAGE_FILE.read_bytes()
            self._send_cors_headers()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(data)
        else:
            self.send_response(404)
            self.end_headers()
            self.wfile.write(b'{"error":"no usage data yet"}')

    def do_POST(self):
        if self.path != "/usage":
            self.send_response(404)
            self.end_headers()
            return
        try:
            length = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(length)
            data = json.loads(body)
            USAGE_FILE.parent.mkdir(parents=True, exist_ok=True)
            USAGE_FILE.write_text(json.dumps(data, indent=2))
            self._send_cors_headers()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(b'{"ok":true}')
        except Exception as e:
            self.send_response(500)
            self.end_headers()
            self.wfile.write(json.dumps({"error": str(e)}).encode())

    def _send_cors_headers(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")

    def log_message(self, fmt, *args):
        pass  # stay silent


def main():
    signal.signal(signal.SIGINT, lambda *_: sys.exit(0))
    signal.signal(signal.SIGTERM, lambda *_: sys.exit(0))
    server = HTTPServer(("127.0.0.1", PORT), Handler)
    print(f"Claude usage bridge listening on http://127.0.0.1:{PORT}", flush=True)
    server.serve_forever()


if __name__ == "__main__":
    main()
