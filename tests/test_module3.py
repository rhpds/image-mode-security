import importlib.util
from pathlib import Path
import tempfile
import unittest

path = Path(__file__).parents[1] / "qa-automation/scripts/module-3-validation-bootc.py"
spec = importlib.util.spec_from_file_location("module3", path)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class ComplianceTests(unittest.TestCase):
    def score(self, score="92.53", profile=module.PROFILE, rules="pass"):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "results.xml"
            path.write_text(f'''<Benchmark xmlns="{module.NS['x']}"><TestResult>
              <profile idref="{profile}"/><rule-result><result>{rules}</result></rule-result>
              <score system="urn:xccdf:scoring:default" maximum="100">{score}</score>
              </TestResult></Benchmark>''')
            return module.compliance_score(path)

    def test_valid_completed_scan(self):
        self.assertEqual(self.score(), 92.53)
        self.assertEqual(self.score("100"), 100)

    def test_bad_or_incomplete_scan_cannot_pass(self):
        for score in ("89.99", "NaN", "Infinity", "101"):
            with self.subTest(score=score), self.assertRaises(ValueError):
                self.score(score)
        for rules in ("error", "unknown"):
            with self.subTest(rules=rules), self.assertRaises(ValueError):
                self.score(rules=rules)
        with self.assertRaises(ValueError):
            self.score(profile="different_profile")

    def test_only_expected_denial_counts(self):
        module.verify_denial(1, "runuser: failed to execute ls: Operation not permitted")
        for code, output in [(0, "Operation not permitted"), (1, "Permission denied"),
                             (127, "No such file or directory"), (1, "connection lost")]:
            with self.subTest(output=output), self.assertRaises(ValueError):
                module.verify_denial(code, output)


if __name__ == "__main__":
    unittest.main()
