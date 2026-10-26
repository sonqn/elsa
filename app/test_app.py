import threading
import time
import unittest
import urllib.request
from http.server import ThreadingHTTPServer
from main import Handler

class APITest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
        threading.Thread(target=cls.server.serve_forever, daemon=True).start()
        cls.url = f"http://127.0.0.1:{cls.server.server_port}"
    @classmethod
    def tearDownClass(cls):
        cls.server.shutdown()
        cls.server.server_close()
    def get(self, path):
        with urllib.request.urlopen(self.url + path, timeout=5) as response:
            return response.read()
    def test_health(self):
        for path in ("/healthz", "/readyz"):
            self.assertIn(b"ok", self.get(path))
    def test_quote_cpu_and_metric(self):
        start = time.process_time()
        self.assertIn(b"quote", self.get("/api/quote"))
        self.assertGreaterEqual(time.process_time()-start, 0.095)
        self.assertIn(b"quote_requests_total", self.get("/metrics"))
    def test_unknown(self):
        with self.assertRaises(urllib.error.HTTPError) as error:
            self.get("/missing")
        self.assertEqual(error.exception.code, 404)

if __name__ == "__main__":
    unittest.main()
