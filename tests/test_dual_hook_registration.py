import json
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class DualHookRegistrationTests(unittest.TestCase):
    def test_both_tools_register_the_shared_guard_path(self):
        codex = json.loads((ROOT / "codex/hooks/hooks.json").read_text())
        claude = json.loads((ROOT / "claude/settings.json").read_text())

        codex_command = codex["hooks"]["PreToolUse"][0]["hooks"][0]["command"]
        claude_command = claude["hooks"]["PreToolUse"][0]["hooks"][0]["command"]

        self.assertIn("$CODEX_HOME/hooks/guard-dangerous-commands.py", codex_command)
        self.assertIn("$HOME/.claude/hooks/guard-dangerous-commands.py", claude_command)
        self.assertTrue((ROOT / "shared/hooks/guard-dangerous-commands.py").is_file())

    def test_shared_guard_is_the_only_implementation(self):
        hook_names = list(ROOT.glob("**/guard-dangerous-commands.py"))
        self.assertEqual(
            {path.relative_to(ROOT).as_posix() for path in hook_names},
            {
                "shared/hooks/guard-dangerous-commands.py",
                "hooks/guard-dangerous-commands.py",
            },
        )


if __name__ == "__main__":
    unittest.main()
