#!/usr/bin/env bash
# loop-status.sh — emit AND record a Loop-Stack status line (the LEDGER writer).
#
# NOTE ON PROVENANCE: this script was reconstructed from angled phone photos of
# a laptop screen. The overall shape (PLAN-block grammar validation, ●/♦ status
# glyphs, a `check` audit subcommand, an append-only ledger) is transcribed
# faithfully; a few of the more granular regex/audit checks in the original
# were illegible in the source photos and have been reimplemented here to be
# correct and internally consistent rather than guessed character-for-character.
# Treat this file as "faithful in behavior, not proven byte-identical."
#
# This is a RECORDER, not a gate. It formats a status line, echoes it, and
# appends it (ISO-timestamped) to the ledger. The PLAN block's structure and the
# five STOP conditions are validated; other line text is recorded as written. A
# host with no shell emits the identical lines as plain text and loses only the
# file. Plain bash — the only external dependency is `git`, for the root climb.
#
# Ledger path: <AGENT_WS_ROOT>/.agentic-loops/loop-ledger.md
# Workspace root resolution:
#   1. AGENT_WS_ROOT if it is set and names a directory; otherwise a warning and:
#   2. the first ancestor of $(pwd) that is NOT inside a git work tree — the
#      ledger must never live inside a repository where it could be committed;
#   3. $HOME if that climb reaches /.
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage:
  loop-status.sh PLAN <-                     # multi-line plan tree from stdin (structure validated)
  loop-status.sh <L0|L1|L2|L3|L4> <text...>  # one status line (a trailing letter, e.g. L2a, is tolerated)
  loop-status.sh STOP <DONE|BLOCKED-EXTERNAL|BLOCKED-AMBIGUOUS|NO-PROGRESS|BUDGET> <note...>
  loop-status.sh LEDGER <text...>            # one-line note that closes a loop
  loop-status.sh check [minutes=30]          # audit: PLAN recorded, recent activity, STOP/Ledger paired

Lines are echoed AND appended (ISO-timestamped) to:
  <AGENT_WS_ROOT-or-first-non-repo-ancestor>/.agentic-loops/loop-ledger.md
EOF
  exit 2
}

_find_ws_root() {
  if [ -n "${AGENT_WS_ROOT:-}" ]; then
    if [ -d "${AGENT_WS_ROOT}" ]; then echo "$AGENT_WS_ROOT"; return; fi
    echo "loop-status.sh: AGENT_WS_ROOT='$AGENT_WS_ROOT' is not a directory — using the repo climb instead" >&2
  fi
  local dir="$(pwd)" top
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

# ---------------------------------------------------------------------------
# check: audit the ledger for a live, well-formed discipline trail
# ---------------------------------------------------------------------------
if [ "${1:-}" = "check" ]; then
  window_min="${2:-30}"
  case "$window_min" in ''|*[!0-9]*) echo "loop-status.sh check: [minutes] must be an integer" >&2; exit 2 ;; esac

  if [ ! -f "$ledger" ]; then
    echo "CHECK: WARN — no ledger at $ledger (the loop discipline left no audit trail)"
    exit 2
  fi

  fail=0

  if ! grep -qE '(◇|●) PLAN' "$ledger"; then
    echo "CHECK: WARN — ledger has no PLAN entry (a plan was never emitted as a tool action)"
    fail=1
  fi

  cutoff_epoch=$(( $(date -u +%s) - window_min * 60 ))
  last_ts="$(grep -oE '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z' "$ledger" | tail -1 || true)"
  if [ -z "$last_ts" ]; then
    echo "CHECK: WARN — ledger has no timestamped entries"
    fail=1
  else
    last_epoch="$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$last_ts" +%s 2>/dev/null \
               || date -u -d "$last_ts" +%s)"
    if [ "$last_epoch" -lt "$cutoff_epoch" ]; then
      echo "CHECK: WARN — last ledger entry ($last_ts) is older than ${window_min}m (chat may not be mirrored to the ledger)"
      fail=1
    fi
  fi

  stops="$(grep -c 'STOP: DONE' "$ledger" || true)"
  ledgers="$(grep -c 'Ledger:' "$ledger" || true)"
  if [ "${stops:-0}" -gt "${ledgers:-0}" ]; then
    echo "CHECK: WARN — $stops STOP:DONE line(s) but only $ledgers Ledger: line(s) (every DONE must close with a Ledger: line)"
    fail=1
  fi

  if [ "$fail" -eq 1 ]; then
    echo "CHECK: FAIL — see WARN lines above ($ledger)"
    exit 1
  fi
  echo "CHECK: PASS — ledger present, PLAN recorded, activity within ${window_min}m, STOP/Ledger paired ($ledger)"
  exit 0
fi

[ "$#" -ge 1 ] || usage

level="$1"
shift || true

case "$level" in
  # -------------------------------------------------------------------------
  # PLAN <- : read a full plan tree from stdin, validate its grammar, record it
  # -------------------------------------------------------------------------
  PLAN)
    [ "${1:-}" = "<-" ] || usage
    block="$(cat)"

    first_line="$(printf '%s\n' "$block" | head -1)"
    case "$first_line" in
      '◇ PLAN'*|'● PLAN'*|'TASK '*|'TASK') ;;
      *) echo "loop-status.sh: REJECTED — a PLAN block must start with '◇ PLAN' or a 'TASK' root line (got: '$first_line')" >&2; exit 2 ;;
    esac

    TAB="$(printf '\t')"
    lineno=0
    while IFS= read -r line; do
      lineno=$((lineno + 1))
      [ "$lineno" -eq 1 ] && continue   # header already validated
      [ -z "$line" ] && continue        # blank lines allowed

      case "$line" in
        *"$TAB"*)
          echo "loop-status.sh: REJECTED — plan indentation must be spaces, not tabs (line $lineno: '$line')" >&2
          exit 2 ;;
      esac

      lead="${line%%[!\ ]*}"
      if [ $(( ${#lead} % 2 )) -ne 0 ]; then
        echo "loop-status.sh: REJECTED — plan indentation must be a multiple of two spaces (line $lineno: '$line')" >&2
        exit 2
      fi

      body="${line#"$lead"}"
      case "$body" in
        '●'*|'○'*)
          if ! printf '%s' "$body" | grep -q 'stop:'; then
            echo "loop-status.sh: REJECTED — an open/pending plan line (●/○) must carry 'stop:<condition>' (line $lineno: '$body')" >&2
            exit 2
          fi
          ;;
        *) ;;  # closed (✓), abandoned (~~ / —), TASK, ◇ PLAN, and free-text notes need no stop:
      esac
    done <<PLAN_BLOCK
$block
PLAN_BLOCK

    mkdir -p "$(dirname "$ledger")"
    { printf '%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"; printf '%s\n' "$block"; } >> "$ledger"
    printf '%s\n' "$block"
    exit 0
    ;;

  # -------------------------------------------------------------------------
  # L0-L4: a single status line. Concurrent loops are told apart by their
  # [piece] tag in the text, not a letter suffix — but a trailing letter
  # (L2a) is tolerated so older muscle memory doesn't error out.
  # -------------------------------------------------------------------------
  L[0-4]|L[0-4][a-z])
    text="$*"
    [ -n "$text" ] || { echo "loop-status.sh: REJECTED — $level requires status text" >&2; exit 2; }
    line="◆ ${level} ${text}"
    ;;

  # -------------------------------------------------------------------------
  # STOP: the first token must name one of the five stop conditions
  # -------------------------------------------------------------------------
  STOP)
    text="$*"
    [ -n "$text" ] || { echo "loop-status.sh: REJECTED — STOP requires a named condition" >&2; exit 2; }
    cond="${text%% *}"
    case "$cond" in
      DONE|BLOCKED-EXTERNAL|BLOCKED-AMBIGUOUS|NO-PROGRESS|BUDGET) ;;
      *) echo "loop-status.sh: REJECTED — STOP must name one of: DONE BLOCKED-EXTERNAL BLOCKED-AMBIGUOUS NO-PROGRESS BUDGET (got: '$cond')" >&2; exit 2 ;;
    esac
    line="◆ STOP: ${text}"
    ;;

  # -------------------------------------------------------------------------
  # LEDGER: the one-line audit note that closes a loop
  # -------------------------------------------------------------------------
  LEDGER)
    text="$*"
    [ -n "$text" ] || { echo "loop-status.sh: REJECTED — LEDGER requires text" >&2; exit 2; }
    line="Ledger: ${text}"
    ;;

  *)
    echo "loop-status.sh: REJECTED — unknown level '$level' (expected L0-L4|PLAN|STOP|LEDGER|check)" >&2
    exit 2
    ;;
esac

mkdir -p "$(dirname "$ledger")"
printf '%s\n' "$line"
printf '%s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$line" >> "$ledger"
