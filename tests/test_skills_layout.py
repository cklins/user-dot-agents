import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SKILLS = ROOT / "skills"


class SkillsLayoutTests(unittest.TestCase):
    def test_every_top_level_skill_has_skill_file(self):
        skill_dirs = [path for path in SKILLS.iterdir() if path.is_dir()]
        self.assertGreater(len(skill_dirs), 0)
        for skill_dir in skill_dirs:
            self.assertTrue(
                (skill_dir / "SKILL.md").is_file(),
                f"missing SKILL.md in {skill_dir.name}",
            )

    def test_setup_skill_supports_both_agent_instruction_files(self):
        content = (SKILLS / "setup-matt-pocock-skills" / "SKILL.md").read_text()
        self.assertIn("AGENTS.md", content)
        self.assertIn("CLAUDE.md", content)


if __name__ == "__main__":
    unittest.main()
