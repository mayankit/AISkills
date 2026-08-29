#!/usr/bin/env bash
# install.sh — wire aiSkills into a host from this repo. Idempotent and re-runnable.
#
#   ./install.sh                 # Claude Code (default host)
#   ./install.sh claude-code     # same, explicit
#   ./install.sh --no-activate   # copy the files but don't touch settings.json
#   ./install.sh --dry-run       # print what would happen, change nothing
#   ./install.sh --uninstall     # remove everything this script installed
#   ./install.sh --help
#
# Everything is copied FROM this repository. Nothing is authored in place.
# Honors $CLAUDE_CONFIG_DIR (defaults to ~/.claude).
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOST="claude-code"; DRY=0; UNINSTALL=0; ACTIVATE=1

for a in "$@"; do
  case "$a" in
    claude-code)   HOST="claude-code" ;;
    --uninstall)   UNINSTALL=1 ;;
    --dry-run)     DRY=1 ;;
    --no-activate) ACTIVATE=0 ;;
    -h|--help)     sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "install.sh: unknown argument '$a' (try --help)" >&2; exit 2 ;;
  esac
done

CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SKILLS_DIR="$CLAUDE_DIR/skills"
AGENTS_DIR="$CLAUDE_DIR/agents"
STYLES_DIR="$CLAUDE_DIR/output-styles"
SETTINGS="$CLAUDE_DIR/settings.json"
CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"
STYLE_NAME="Loops Within Loops"
STYLE_DST="$STYLES_DIR/loops-within-loops.md"
STYLE_SRC="$REPO/output-styles/loops-within-loops.md"

say() { printf '%s\n' "$*"; }
run() { printf '  + %s\n' "$*"; [ "$DRY" -eq 1 ] || eval "$*"; }

# --- JSON key set/unset via python3, with a one-file backup -------------------
_json_set()   { python3 -c 'import json,sys; p=sys.argv[1]; d=json.load(open(p)) if __import__("os").path.exists(p) else {}; d[sys.argv[2]]=sys.argv[3]; json.dump(d,open(p,"w"),indent=2); open(p,"a").write("\n")' "$1" "$2" "$3"; }
_json_unset() { python3 -c 'import json,sys,os; p=sys.argv[1]; d=json.load(open(p)); d.pop(sys.argv[2],None) if d.get(sys.argv[2])==sys.argv[3] else None; json.dump(d,open(p,"w"),indent=2); open(p,"a").write("\n")' "$1" "$2" "$3"; }

strip_legacy_brain() {
  # Older installs appended the brain to ~/.claude/CLAUDE.md between sentinels.
  # The output style supersedes it — remove any such block so state is clean.
  [ -f "$CLAUDE_MD" ] || return 0
  grep -qE 'aiskills-brain-begin|BEGIN aiSkills brain' "$CLAUDE_MD" 2>/dev/null || return 0
  run "cp '$CLAUDE_MD' '$CLAUDE_MD.aiskills-bak'"
  run "sed -i.tmp -e '/<!-- aiskills-brain-begin -->/,/<!-- aiskills-brain-end -->/d' -e '/<!-- BEGIN aiSkills brain/,/<!-- END aiSkills brain -->/d' '$CLAUDE_MD' && rm -f '$CLAUDE_MD.tmp'"
  say "  (removed the legacy CLAUDE.md brain block — superseded by the output style; backup: $CLAUDE_MD.aiskills-bak)"
}

install_claude_code() {
  [ -f "$STYLE_SRC" ] || { echo "install.sh: missing $STYLE_SRC — run from a full checkout" >&2; exit 1; }
  run "mkdir -p '$SKILLS_DIR' '$AGENTS_DIR' '$STYLES_DIR'"

  say "skills →  $SKILLS_DIR/"
  for d in "$REPO"/skills/aiskills-*/; do
    n="$(basename "$d")"
    run "rm -rf '$SKILLS_DIR/$n' && cp -R '$d' '$SKILLS_DIR/$n'"
  done

  say "agents →  $AGENTS_DIR/"
  for f in "$REPO"/agents/aiskills-*.agent.md; do
    b="$(basename "${f%.agent.md}")"
    run "cp '$f' '$AGENTS_DIR/$b.md'"
  done

  say "output style →  $STYLE_DST"
  run "cp '$STYLE_SRC' '$STYLE_DST'"

  strip_legacy_brain

  if [ "$ACTIVATE" -eq 1 ]; then
    if command -v python3 >/dev/null 2>&1; then
      say "activate →  $SETTINGS  (outputStyle = \"$STYLE_NAME\")"
      [ "$DRY" -eq 1 ] || { mkdir -p "$CLAUDE_DIR"; [ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"; cp "$SETTINGS" "$SETTINGS.aiskills-bak"; }
      run "_json_set '$SETTINGS' outputStyle '$STYLE_NAME'"
    else
      ACTIVATE=0
      say "activate →  skipped (python3 not found)"
    fi
  fi

  say ""
  say "Done. $(ls -d "$SKILLS_DIR"/aiskills-* 2>/dev/null | wc -l | tr -d ' ') skills, 4 agents, 1 output style — all copied from this repo."
  if [ "$ACTIVATE" -eq 1 ]; then
    say "Start a NEW Claude Code session to load it.  Disable with:  /output-style default"
  else
    say "Turn it on inside Claude Code with:  /output-style \"$STYLE_NAME\""
  fi
}

uninstall_claude_code() {
  say "removing skills, agents, output style from $CLAUDE_DIR"
  for d in "$REPO"/skills/aiskills-*/; do run "rm -rf '$SKILLS_DIR/$(basename "$d")'"; done
  for f in "$REPO"/agents/aiskills-*.agent.md; do run "rm -f '$AGENTS_DIR/$(basename "${f%.agent.md}").md'"; done
  run "rm -f '$STYLE_DST'"
  if [ -f "$SETTINGS" ] && command -v python3 >/dev/null 2>&1; then
    [ "$DRY" -eq 1 ] || cp "$SETTINGS" "$SETTINGS.aiskills-bak"
    run "_json_unset '$SETTINGS' outputStyle '$STYLE_NAME'"
  fi
  strip_legacy_brain
  say ""
  say "Uninstalled. (Backups left as *.aiskills-bak where anything was edited.)"
}

case "$HOST" in
  claude-code) [ "$UNINSTALL" -eq 1 ] && uninstall_claude_code || install_claude_code ;;
  *) echo "install.sh: unsupported host '$HOST'" >&2; exit 2 ;;
esac
