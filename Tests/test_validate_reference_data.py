import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
VALIDATOR = ROOT / "scripts" / "validate_reference_data.py"


class ReferenceValidationTests(unittest.TestCase):
    def validate(self, reviewed_on="2026-01-01", edition="Test edition"):
        record = {
            "id": "REF-900",
            "topic": "Test topic",
            "category": "app_scope",
            "tags": ["test topic", "fixture"],
            "summary": "Test summary",
            "aiContext": "Test context",
            "relatedCalculation": None,
            "source": {
                "title": "Test source",
                "publisher": "Test publisher",
                "edition": edition,
                "section": "Test section",
            },
            "verification": {
                "status": "verified",
                "reviewedBy": "Test reviewer",
                "reviewedOn": reviewed_on,
            },
        }
        data = {
            "schemaVersion": "1.0",
            "datasetVersion": "test",
            "disclaimer": "Test only",
            "records": [record],
        }
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "records.json"
            path.write_text(json.dumps(data), encoding="utf-8")
            return subprocess.run(
                [sys.executable, str(VALIDATOR), str(path)],
                capture_output=True,
                text=True,
                check=False,
            )

    def test_calendar_date_must_exist(self):
        self.assertEqual(self.validate(reviewed_on="2024-02-29").returncode, 0)
        result = self.validate(reviewed_on="2026-02-30")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("valid calendar date", result.stdout)

    def test_source_placeholders_are_case_insensitive(self):
        result = self.validate(edition="to verify")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("TO VERIFY", result.stdout)


if __name__ == "__main__":
    unittest.main()
