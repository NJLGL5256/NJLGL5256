from __future__ import annotations

import os
import tempfile
import unittest

from autogen_studio.credential_loader import load_api_key


class CredentialLoaderTests(unittest.TestCase):
    def test_loads_from_environment_first(self) -> None:
        os.environ["OPENAI_API_KEY"] = "env-value"
        try:
            self.assertEqual(load_api_key("OPENAI_API_KEY"), "env-value")
        finally:
            os.environ.pop("OPENAI_API_KEY", None)

    def test_falls_back_to_dotenv(self) -> None:
        os.environ.pop("OPENAI_API_KEY", None)
        with tempfile.NamedTemporaryFile("w", delete=False) as handle:
            handle.write("OPENAI_API_KEY=dotenv-value\n")
            dotenv_path = handle.name

        self.assertEqual(load_api_key("OPENAI_API_KEY", dotenv_path=dotenv_path), "dotenv-value")

    def test_raises_when_missing(self) -> None:
        os.environ.pop("OPENAI_API_KEY", None)
        with self.assertRaises(RuntimeError):
            load_api_key("OPENAI_API_KEY", dotenv_path="/tmp/does-not-exist")


if __name__ == "__main__":
    unittest.main()
