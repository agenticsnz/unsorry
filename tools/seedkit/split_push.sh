#!/usr/bin/env bash
# Split a generated working tree into one queued/prove/<id> branch per goal,
# each branched off origin/main, committed, and pushed. Push-only: opens no PRs
# (the scheduled dispatcher opens and auto-merges queued/prove/* branches).
#
# Usage: split_push.sh <made.txt>
#   where <made.txt> holds one `gid|name|Module|sha` line per goal (the output
#   of mkfiles.py). The 5 artifact files for each goal must already exist in the
#   working tree.
#
# Env: SEEDKIT_AGENT  (branch/commit agent id, default "seedkit")
#      SEEDKIT_BRANCH (working branch to return to, default current branch)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
cd "$REPO_ROOT"

MADE="${1:?usage: split_push.sh <made.txt>}"
AGENT="${SEEDKIT_AGENT:-seedkit}"
WORK_BRANCH="${SEEDKIT_BRANCH:-$(git rev-parse --abbrev-ref HEAD)}"

git fetch origin main --quiet

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
cp -r backlog goals library "$STAGE/"

while IFS='|' read -r gid name mod sha; do
  [ -n "$gid" ] || continue
  hex="$(openssl rand -hex 3)"
  br="queued/prove/$gid/$AGENT-$hex"
  git checkout -q -B "$br" origin/main
  cp "$STAGE/backlog/$gid.md"            "backlog/$gid.md"
  cp "$STAGE/goals/$gid.lean"            "goals/$gid.lean"
  cp "$STAGE/goals/$gid.aisp"            "goals/$gid.aisp"
  cp "$STAGE/library/Unsorry/$mod.lean" "library/Unsorry/$mod.lean"
  cp "$STAGE/library/index/$sha.aisp"   "library/index/$sha.aisp"
  git add "backlog/$gid.md" "goals/$gid.lean" "goals/$gid.aisp" \
          "library/Unsorry/$mod.lean" "library/index/$sha.aisp"
  git commit -q -m "prove($gid): $name by $AGENT"
  n=0
  until git push -u origin "$br"; do
    n=$((n + 1))
    if [ "$n" -gt 4 ]; then echo "PUSH FAILED: $br" >&2; break; fi
    sleep $((2 ** n))
  done
  echo "pushed $br"
done < "$MADE"

git checkout -q "$WORK_BRANCH"
