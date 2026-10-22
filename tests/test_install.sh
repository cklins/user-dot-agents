#!/usr/bin/env bash
set -eu

REPO="$(cd "$(dirname "$0")/.." && pwd)"
TEST_HOME="$(mktemp -d)"
trap 'rm -rf "$TEST_HOME"' EXIT

mkdir -p "$TEST_HOME/.agents" "$TEST_HOME/.codex" "$TEST_HOME/.claude" "$TEST_HOME/.config"
printf existing >"$TEST_HOME/.codex/AGENTS.md"
HOME="$TEST_HOME" bash "$REPO/install.sh"

[ "$(readlink "$TEST_HOME/.agents/skills")" = "$REPO/skills" ]
[ "$(readlink "$TEST_HOME/.claude/skills")" = "$REPO/skills" ]
[ "$(readlink "$TEST_HOME/.codex/hooks")" = "$REPO/shared/hooks" ]
[ "$(readlink "$TEST_HOME/.codex/hooks.json")" = "$REPO/codex/hooks/hooks.json" ]
[ "$(readlink "$TEST_HOME/.codex/AGENTS.md")" = "$REPO/codex/AGENTS.md" ]
[ "$(readlink "$TEST_HOME/.claude/hooks")" = "$REPO/shared/hooks" ]
[ "$(readlink "$TEST_HOME/.claude/settings.json")" = "$REPO/claude/settings.json" ]
[ "$(readlink "$TEST_HOME/.claude/CLAUDE.md")" = "$REPO/claude/CLAUDE.md" ]
[ "$(readlink "$TEST_HOME/.claude/output-styles")" = "$REPO/claude/output-styles" ]
[ "$(readlink "$TEST_HOME/.config/ccstatusline/settings.json")" = "$REPO/claude/ccstatusline/settings.json" ]
test "$(find "$TEST_HOME/.codex" -name 'AGENTS.md.backup-*' | wc -l)" -eq 1

HOME="$TEST_HOME" bash "$REPO/install.sh"
test "$(find "$TEST_HOME/.codex" -name 'AGENTS.md.backup-*' | wc -l)" -eq 1

rm "$TEST_HOME/.codex/hooks.json"
ln -s "$TEST_HOME/missing" "$TEST_HOME/.codex/hooks.json"
HOME="$TEST_HOME" bash "$REPO/install.sh"
[ "$(readlink "$TEST_HOME/.codex/hooks.json")" = "$REPO/codex/hooks/hooks.json" ]
test "$(find "$TEST_HOME/.codex" -name 'hooks.json.backup-*' | wc -l)" -eq 1
