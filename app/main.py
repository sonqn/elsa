import hashlib
import json
import random
import signal
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

QUOTES = ["Keep learning.", "Small steps build great things.", "Make it work, then make it better."]
LOCK = threading.Lock()
REQUESTS = 0

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        global REQUESTS
        with LOCK:
            REQUESTS += 1
            count = REQUESTS
        status, content_type = 200, "application/json"
        if self.path in ("/healthz", "/readyz"):
            body = b'{"status":"ok"}'
        elif self.path == "/api/quote":
            # Per-thread CPU clock: 100ms CPU, not a sleep or wall-time delay.
            start = time.thread_time()
            data = b"quote"
            while time.thread_time() - start < 0.1:
                data = hashlib.sha256(data).digest()
            body = json.dumps({"quote": random.choice(QUOTES)}).encode()
        elif self.path == "/metrics":
            content_type = "text/plain; version=0.0.4"
            body = ("# HELP quote_requests_total Total HTTP requests.\n"
                    "# TYPE quote_requests_total counter\n"
                    f"quote_requests_total {count}\n").encode()
        else:
            status, body = 404, b'{"error":"not found"}'
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

if __name__ == "__main__":
    with ThreadingHTTPServer(("0.0.0.0", 8080), Handler) as server:
        server.daemon_threads = False  # Finish active requests before closing.
        stopping = threading.Event()

        def stop_server(signum, frame):
            if not stopping.is_set():
                stopping.set()
                # shutdown() must run outside the serve_forever thread.
                threading.Thread(target=server.shutdown, daemon=True).start()

        signal.signal(signal.SIGTERM, stop_server)
        signal.signal(signal.SIGINT, stop_server)
        server.serve_forever(poll_interval=0.1)
