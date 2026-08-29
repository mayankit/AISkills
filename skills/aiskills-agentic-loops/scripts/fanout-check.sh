#!/usr/bin/env bash
# fanout-check.sh — the fan-out decision as a recorded checklist tool.
#
# Applies the aiskills-agentic-loops fan-out trigger (>=2 independent pieces, no shared
# mutable file — dispatch together in ONE turn), renders the decision to
# stdout, and appends it to the same loop ledger loop-status.sh writes to — so
# the fan-out decision is auditable, not just prose discipline.
#
# Usage:
#   bash fanout-check.sh <number-of-pieces> [shared-mutable-file? yes|no]
#   (shared defaults to "no")
#
# Examples:
#   fanout-check.sh 3           -> FAN-OUT REQUIRED: dispatch all 3 pieces.
#   fanout-check.sh 3 yes       -> SEQUENCE: pieces share mutable state ...
#   fanout-check.sh 1           -> SINGLE PIECE: no fan-out.
#
# Ledger location: <AGENT_WS_ROOT>/.agentic-loops/loop-ledger.md
# Same deterministic root resolution as loop-status.sh:
#   AGENT_WS_ROOT override -> climb out of git repos -> cwd -> $HOME.
# Never put a git repo root (a ledger inside a repo can be accidentally committed).
set -euo pipefail

usage() {
  echo "Usage: fanout-check.sh <number-of-pieces> [shared-mutable-file? yes|no]" >&2
  exit 2
}

[ "$#" -ge 1 ] && [ "$#" -le 2 ] || usage

n="$1"
shared="${2:-no}"

case "$n" in
  ''|*[!0-9]*) echo "fanout-check.sh: <number-of-pieces> must be a non-negative integer" >&2; usage ;;
esac
case "$shared" in
  yes|no) ;;
  *) echo "fanout-check.sh: shared-mutable-file must be yes|no" >&2; usage ;;
esac

if [ "$shared" = "yes" ]; then
  decision="SEQUENCE: pieces share mutable state — define the interface contract, then sequence or re-partition."
elif [ "$n" -ge 2 ]; then
  decision="FAN-OUT REQUIRED: dispatch all $n piece(s) as subagent/tool calls in ONE turn — do not await between independent dispatches."
else
  decision="SINGLE PIECE: no fan-out."
fi

_find_ws_root() {
  if [ -n "${AGENT_WS_ROOT:-}" ] && [ -d "${AGENT_WS_ROOT}" ]; then
    echo "$AGENT_WS_ROOT"
    return
  fi
  local dir top
  dir="$(pwd)"
  while [ "$dir" != "/" ]; do
    top="$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null || true)"
    [ -z "$top" ] && break
    dir="$(dirname "$top")"
  done
  if [ "$dir" != "/" ]; then
    echo "$dir"
    return
  fi
  echo "$HOME"
}

ledger="$(_find_ws_root)/.agentic-loops/loop-ledger.md"
mkdir -p "$(dirname "$ledger")"

printf '%s\n' "$decision"
printf '%s | fanout-check | %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$decision" >> "$ledger"
