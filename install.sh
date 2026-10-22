#!/usr/bin/env bash
# Install shared, Codex-specific, and Claude Code-specific user configuration.
set -u

SCRIPT_SOURCE="${BASH_SOURCE[0]:-$0}"
REPO="$(cd "$(dirname "$SCRIPT_SOURCE")" && pwd)"
[ -n "$REPO" ] || { echo "✗ 無法解析 repo 根目錄。" >&2; exit 1; }

case "$(uname -s 2>/dev/null || echo unknown)" in
  MINGW*|MSYS*|CYGWIN*)
    export MSYS=winsymlinks:nativestrict
    export CYGWIN="${CYGWIN:-} winsymlinks:nativestrict"
    echo "ℹ️  偵測到 Windows(Git Bash/MSYS)。建立 symlink 需開發人員模式或系統管理員權限。" ;;
esac

CODEX_DIR="$HOME/.codex"
CLAUDE_DIR="$HOME/.claude"
AGENTS_DIR="$HOME/.agents"
CONFIG_DIR="$HOME/.config"
STAMP="$(date +%Y%m%d-%H%M%S 2>/dev/null || echo backup)"
FAILED=0

make_link() {
  local src="$1" dest="$2" current_target

  if [ ! -e "$src" ]; then
    echo "  ✗ 來源不存在：$src" >&2
    FAILED=$((FAILED + 1))
    return 1
  fi

  if ! mkdir -p "$(dirname "$dest")"; then
    echo "  ✗ 建立目錄失敗：$(dirname "$dest")" >&2
    FAILED=$((FAILED + 1))
    return 1
  fi

  if [ -L "$dest" ]; then
    current_target="$(readlink "$dest")"
    if [ "$current_target" = "$src" ]; then
      rm -f "$dest"
    else
      if ! mv "$dest" "${dest}.backup-${STAMP}"; then
        echo "  ✗ 備份既有連結失敗：$dest" >&2
        FAILED=$((FAILED + 1))
        return 1
      fi
      echo "  ⚑ 已備份既有連結：$dest -> ${dest}.backup-${STAMP}"
    fi
  elif [ -e "$dest" ]; then
    if ! mv "$dest" "${dest}.backup-${STAMP}"; then
      echo "  ✗ 備份既有檔案失敗：$dest" >&2
      FAILED=$((FAILED + 1))
      return 1
    fi
    echo "  ⚑ 已備份既有檔案：$dest -> ${dest}.backup-${STAMP}"
  fi

  if ln -s "$src" "$dest"; then
    echo "  ✓ $dest -> $src"
  else
    echo "  ✗ 建立 symlink 失敗：$dest" >&2
    FAILED=$((FAILED + 1))
    return 1
  fi
}

echo "Repo：$REPO"
echo "家目錄：$HOME"

echo "[1/10] shared skills -> ~/.agents/skills"
make_link "$REPO/skills" "$AGENTS_DIR/skills"
echo "[2/10] shared skills -> ~/.claude/skills"
make_link "$REPO/skills" "$CLAUDE_DIR/skills"

echo "[3/10] shared hooks -> ~/.codex/hooks"
make_link "$REPO/shared/hooks" "$CODEX_DIR/hooks"
echo "[4/10] Codex hook registration"
make_link "$REPO/codex/hooks/hooks.json" "$CODEX_DIR/hooks.json"
echo "[5/10] Codex AGENTS.md"
make_link "$REPO/codex/AGENTS.md" "$CODEX_DIR/AGENTS.md"

echo "[6/10] shared hooks -> ~/.claude/hooks"
make_link "$REPO/shared/hooks" "$CLAUDE_DIR/hooks"
echo "[7/10] Claude Code settings"
make_link "$REPO/claude/settings.json" "$CLAUDE_DIR/settings.json"
echo "[8/10] Claude Code CLAUDE.md"
make_link "$REPO/claude/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
echo "[9/10] Claude Code output styles"
make_link "$REPO/claude/output-styles" "$CLAUDE_DIR/output-styles"
echo "[10/10] ccstatusline settings"
make_link "$REPO/claude/ccstatusline/settings.json" "$CONFIG_DIR/ccstatusline/settings.json"

if [ "$FAILED" -eq 0 ]; then
  echo "✅ Codex 與 Claude Code 設定安裝完成。"
else
  echo "⚠️  有 $FAILED 項安裝失敗。" >&2
  exit 1
fi
