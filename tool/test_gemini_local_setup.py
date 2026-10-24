"""Tests for key isolation and HTTP behavior of the local Gemini demo proxy."""

from __future__ import annotations

import json
import sys
import threading
import unittest
from http.server import ThreadingHTTPServer
from pathlib import Path
from unittest.mock import MagicMock, patch
from urllib.request import Request, urlopen
from urllib.error import HTTPError

sys.path.insert(0, str(Path(__file__).resolve().parent))
import gemini_local_setup as setup  # noqa: E402


class LocalProxyTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.server = ThreadingHTTPServer(("127.0.0.1", 0), setup.Handler)
        cls.server_thread = threading.Thread(target=cls.server.serve_forever, daemon=True)
        cls.server_thread.start()
        cls.base_url = f"http://127.0.0.1:{cls.server.server_port}"

    @classmethod
    def tearDownClass(cls) -> None:
        cls.server.shutdown()
        cls.server.server_close()
        cls.server_thread.join(timeout=2)

    def setUp(self) -> None:
        self.original_key = setup.GEMINI_API_KEY
        setup.GEMINI_API_KEY = ""

    def tearDown(self) -> None:
        setup.GEMINI_API_KEY = self.original_key

    def test_health_does_not_disclose_key(self) -> None:
        setup.GEMINI_API_KEY = "local-test-secret"
        with urlopen(f"{self.base_url}/status") as response:
            body = response.read().decode("utf-8")
        self.assertEqual(json.loads(body), {"ready": True})
        self.assertNotIn("local-test-secret", body)

    def test_proxy_refuses_until_key_is_configured(self) -> None:
        req = Request(
            f"{self.base_url}/v1beta/models/{setup.MODEL}:generateContent",
            data=b'{"contents": []}',
            headers={"Content-Type": "application/json", "Origin": "http://localhost:8083"},
            method="POST",
        )
        with self.assertRaises(HTTPError) as error:
            urlopen(req)
        payload = json.loads(error.exception.read().decode("utf-8"))
        self.assertEqual(error.exception.code, 503)
        self.assertEqual(payload["error"]["status"], "HHL_AI_NOT_CONFIGURED")
        self.assertNotIn("API key", json.dumps(payload))
        error.exception.close()

    def test_proxy_forwards_key_only_to_google_and_redacts_it_from_client(self) -> None:
        setup.GEMINI_API_KEY = "local-test-secret"
        upstream = MagicMock()
        upstream.__enter__.return_value.status = 200
        upstream.__enter__.return_value.read.return_value = b'{"candidates": []}'

        with patch.object(setup, "urlopen", return_value=upstream) as open_google:
            req = Request(
                f"{self.base_url}/v1beta/models/{setup.MODEL}:generateContent",
                data=b'{"contents": []}',
                headers={"Content-Type": "application/json", "Origin": "http://localhost:8083"},
                method="POST",
            )
            with urlopen(req) as response:
                body = response.read().decode("utf-8")
                self.assertEqual(response.headers["Access-Control-Allow-Origin"], "http://localhost:8083")
        upstream_request = open_google.call_args.args[0]
        self.assertEqual(upstream_request.get_header("X-goog-api-key"), "local-test-secret")
        self.assertNotIn("local-test-secret", body)

    def test_proxy_rejects_unapproved_browser_origin(self) -> None:
        setup.GEMINI_API_KEY = "local-test-secret"
        req = Request(
            f"{self.base_url}/v1beta/models/{setup.MODEL}:generateContent",
            data=b'{"contents": []}',
            headers={"Content-Type": "application/json", "Origin": "https://attacker.invalid"},
            method="POST",
        )
        with self.assertRaises(HTTPError) as error:
            urlopen(req)
        self.assertEqual(error.exception.code, 403)
        self.assertNotIn("Access-Control-Allow-Origin", error.exception.headers)
        error.exception.close()


if __name__ == "__main__":
    unittest.main()
