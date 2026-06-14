import http.client
import importlib.util
import json
import os
import tempfile
import threading
import unittest
from pathlib import Path

SERVER_PATH = Path(__file__).resolve().parents[1] / "src" / "server.py"
SPEC = importlib.util.spec_from_file_location("pingsheng_server", SERVER_PATH)
server = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(server)


class ChunkedRegistrationTest(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.previous_env = {
            "DATA_FILE": os.environ.get("DATA_FILE"),
            "DOWNLOAD_DIR": os.environ.get("DOWNLOAD_DIR"),
            "TOKEN_SECRET": os.environ.get("TOKEN_SECRET"),
            "ADMIN_TOKEN": os.environ.get("ADMIN_TOKEN"),
        }
        os.environ["DATA_FILE"] = str(Path(self.temp_dir.name) / "db.json")
        os.environ["DOWNLOAD_DIR"] = str(Path(self.temp_dir.name) / "downloads")
        os.environ["TOKEN_SECRET"] = "test-token-secret"
        os.environ["ADMIN_TOKEN"] = "test-admin-token"
        self.httpd = server.ThreadingHTTPServer(("127.0.0.1", 0), server.Handler)
        self.thread = threading.Thread(target=self.httpd.serve_forever, daemon=True)
        self.thread.start()

    def tearDown(self):
        self.httpd.shutdown()
        self.thread.join(timeout=5)
        self.httpd.server_close()
        for key, value in self.previous_env.items():
            if value is None:
                os.environ.pop(key, None)
            else:
                os.environ[key] = value
        self.temp_dir.cleanup()

    def post_chunked(self, path, payload):
        body = json.dumps(payload).encode("utf-8")
        conn = http.client.HTTPConnection(
            "127.0.0.1",
            self.httpd.server_address[1],
            timeout=5,
        )
        try:
            conn.request(
                "POST",
                path,
                body=iter([body]),
                headers={
                    "Content-Type": "application/json",
                    "Transfer-Encoding": "chunked",
                },
                encode_chunked=True,
            )
            response = conn.getresponse()
            raw = response.read().decode("utf-8")
            return response.status, json.loads(raw)
        finally:
            conn.close()

    def test_email_registration_accepts_chunked_json(self):
        status, payload = self.post_chunked(
            "/v1/auth/register/email",
            {
                "email": "chunked@example.com",
                "password": "secret123",
                "displayName": "Chunked Email",
            },
        )

        self.assertEqual(status, 201)
        self.assertEqual(payload["user"]["email"], "chunked@example.com")
        self.assertIn("accessToken", payload)

    def test_phone_registration_accepts_chunked_json(self):
        status, payload = self.post_chunked(
            "/v1/auth/register/phone",
            {
                "phone": "13800138001",
                "password": "secret123",
                "displayName": "Chunked Phone",
            },
        )

        self.assertEqual(status, 201)
        self.assertEqual(payload["user"]["phone"], "13800138001")
        self.assertIn("accessToken", payload)


if __name__ == "__main__":
    unittest.main()
