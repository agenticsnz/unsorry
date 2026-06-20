#!/usr/bin/env bash
# Auto-archive one block when the active proved set crosses the ceiling
# (ADR-041 / SPEC-041-A §9 auto-trigger). Keeps the active proved set bounded so
# Gate A's full-replay + `lake build UnsorryLibrary --wfail` stay under memory —
# preventing the exit-137 OOM that a growing active set causes (archived proofs
# are provenance+packaging validated, never re-replayed, ADR-048).
#
# Cuts at most ONE block per run, and only when no archive PR is already open, so
# it serialises behind merges and never floods Gate A. Run by the scheduled
# auto-archive workflow with the dispatcher's REFRESH_TOKEN; safe to run by hand.
set -euo pipefail

ceiling="${CEILING:-40}"
[[ "$ceiling" =~ ^[0-9]+$ ]] || { echo "::error::CEILING must be an integer"; exit 1; }

# Guard: one open archive PR at a time. Re-cutting while a retire PR is pending
# would re-select the same goals (both target main) and conflict.
open_archive="$(gh pr list --state open --limit 100 --json headRefName,title \
  --jq '[.[] | select((.headRefName|startswith("archive/")) or (.title|test("\\(archive\\)")))] | length' \
  2>/dev/null || echo 0)"
if [ "${open_archive:-0}" -gt 0 ]; then
  echo "auto-archive: an archive PR is already open — skipping"
  exit 0
fi

eligible="$(python3 - <<'PY'
from pathlib import Path
from tools.archive.plan import proved_goals, archived_goal_ids
root = Path(".")
archived = archived_goal_ids(root)
print(sum(1 for g in proved_goals(root) if g.goal not in archived))
PY
)"
echo "auto-archive: eligible proved-not-archived = $eligible (ceiling $ceiling)"
if [ "$eligible" -lt "$ceiling" ]; then
  echo "auto-archive: under ceiling — nothing to do"
  exit 0
fi

block="$(python3 -c 'from pathlib import Path; from tools.archive.plan import next_block_id; print(next_block_id(Path(".")))')"
toolchain="$(tr -d '[:space:]' < lean-toolchain)"
# Reuse the most recent block's pinned mathlib tag — the current pin (toolchain
# bumps are dedicated PRs, ADR-002), and a tag (not the lake-manifest commit sha).
mathlib="$(python3 -c 'import json,glob; m=sorted(glob.glob("packages/unsorry-archive-*/archive-manifest.json")); print(json.load(open(m[-1]))["pins"]["mathlib"]) if m else print("")')"
[ -n "$mathlib" ] || { echo "::error::could not determine mathlib pin"; exit 1; }
src="$(git rev-parse HEAD)"
branch="archive/auto-$block"

git config user.name "unsorry-auto-archive"
git config user.email "noreply@unsorry"
git switch -c "$branch"

python3 -m tools.archive.apply --source-commit "$src" --toolchain "$toolchain" --mathlib "$mathlib"

# Validate (SPEC-041-A §8 step 5) before committing.
python3 -m tools.gate_b validate . >/dev/null \
  || { echo "::error::active Gate B failed after cut"; exit 1; }
python3 -m tools.gate_b validate "packages/$block" --goals-root "packages/$block" >/dev/null \
  || { echo "::error::package Gate B failed"; exit 1; }

# Invariant B: the cut must not touch generated docs.
if git status --porcelain -- docs/ | grep -vE 'docs/adrs/|docs/proposals/' | grep -q .; then
  echo "::error::auto-archive touched generated docs (invariant B)"; exit 1
fi

git add -A
git commit -q -m "chore(archive): auto-retire active copies for block $block

Automated ADR-041 / SPEC-041-A §9 cut: active proved-not-archived ($eligible) >=
ceiling ($ceiling). Keeps the active full-replay/build set bounded to prevent the
exit-137 OOM; archived proofs are provenance+packaging validated, not re-replayed
(ADR-048)."

# ADR-018: goal-.lean removals must be allowed by the manifest (byte-identical
# archived copy). Diffs the committed branch against main.
python3 -m tools.gate_a.check_goal_immutability --base origin/main \
  || { echo "::error::goal immutability check failed"; exit 1; }

git push -q -u origin "$branch"
gh pr create --base main --head "$branch" \
  --title "chore(archive): auto-retire active copies for block $block" \
  --body "Automated archive cut (ADR-041 / SPEC-041-A §9 auto-trigger). Active proved-not-archived was **$eligible** ≥ ceiling **$ceiling**, so block \`$block\` was cut to keep the active set bounded and prevent the Gate A OOM (exit 137). Archived proofs are validated by provenance + packaging, not re-replayed (ADR-048). Validated before opening: Gate B (active + package as its own tree), ADR-018 goal immutability, and zero generated-doc delta (invariant B)."
gh pr merge --auto --squash "$branch"
echo "auto-archive: opened + armed auto-merge for $block ($eligible eligible)"
