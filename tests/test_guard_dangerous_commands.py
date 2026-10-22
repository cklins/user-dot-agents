import json
import subprocess
import sys
import unittest
from pathlib import Path


GUARD = Path(__file__).parents[1] / "shared" / "hooks" / "guard-dangerous-commands.py"


def run_guard(payload):
    raw = payload if isinstance(payload, str) else json.dumps(payload)
    result = subprocess.run(
        [sys.executable, str(GUARD)], input=raw, text=True, capture_output=True, check=True
    )
    return result.stdout.strip()


class GuardTests(unittest.TestCase):
    def assert_denied(self, command):
        output = run_guard({"tool_name": "Bash", "tool_input": {"command": command}})
        decision = json.loads(output)["hookSpecificOutput"]
        self.assertEqual(decision["hookEventName"], "PreToolUse")
        self.assertEqual(decision["permissionDecision"], "deny")
        self.assertTrue(decision["permissionDecisionReason"])

    def test_dangerous_commands_are_denied(self):
        for command in (
            "/bin/rm -rf /tmp/example",
            "bash -c \"sudo whoami\"",
            "bash -c '/bin/rm -rf /tmp/example'",
            "find . -name '*.tmp' -delete",
            "git push origin main --force-with-lease",
            "truncate -s 0 important.log",
        ):
            with self.subTest(command=command):
                self.assert_denied(command)

    def test_safe_commands_are_silent(self):
        for command in ("git status", "git push origin feature", "ls -la", "find . -name '*.md'"):
            with self.subTest(command=command):
                self.assertEqual(run_guard({"tool_name": "Bash", "tool_input": {"command": command}}), "")

    def test_irrelevant_or_invalid_inputs_fail_open(self):
        cases = (
            {"tool_name": "Read", "tool_input": {"command": "rm -rf /"}},
            {"tool_name": "Bash", "tool_input": {"command": ""}},
            {"tool_name": "Bash", "tool_input": {}},
            "not-json",
        )
        for payload in cases:
            with self.subTest(payload=payload):
                self.assertEqual(run_guard(payload), "")


if __name__ == "__main__":
    unittest.main()
