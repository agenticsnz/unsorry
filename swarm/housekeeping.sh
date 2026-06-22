#!/usr/bin/env bash
# swarm/housekeeping.sh — the swarm's first work package (ADR-083).
#
# A *swarm operational task*: assign every model in the leaderboard's model
# distribution a unique Pokémon identity (sprite + description + research +
# rationale), published to docs/metrics/model-registry.json for the guild
# frontend. The unit of work is ONE Pokémon for ONE model = exactly ONE PR.
#
# GUARANTEE (ADR-083): run.sh runs this FIRST and blocks on it, so *every*
# unnamed model is resolved before any proving/dispatch/sourcing work begins.
# This drains the whole unnamed list, serialised: each model is named, opened as
# one labelled PR, and SETTLED onto main before the next is started — so the
# single-file registry never sees concurrent edits and uniqueness always holds.
#
# Exit codes: 0 all models named / nothing to do · 1 could not name some model
# (run.sh then refuses to start the proving arms) · 2 config error.
set -euo pipefail
# Force Python UTF-8 everywhere: agent responses carry non-ASCII (accented names,
# em-dashes) and a C locale would otherwise crash stdin decode in the helpers.
export PYTHONUTF8=1

REGISTRY="docs/metrics/model-registry.json"
DISTRIBUTION="docs/metrics/leaderboard-ui.json"
# Models to name per invocation. Default 0 = drain ALL unnamed models (the
# run.sh guarantee). A positive value caps the run (testing/manual use).
MAX="${UNSORRY_REGISTRY_MAX:-0}"
RETRIES="${UNSORRY_REGISTRY_RETRIES:-5}"      # research attempts per model
SETTLE_TRIES="${UNSORRY_REGISTRY_SETTLE_TRIES:-60}"  # merge-settle polls per PR
SETTLE_WAIT="${UNSORRY_REGISTRY_SETTLE_WAIT:-10}"    # seconds between polls
MODEL="${UNSORRY_MODEL:-opus}"
WALL="${UNSORRY_REGISTRY_WALL:-600}"
AGENT_ID="${UNSORRY_AGENT_ID:-housekeeping}"
BASE_BRANCH="${UNSORRY_BASE_BRANCH:-main}"
CONTRIBUTOR=""  # resolved in main(); used by research_and_write()

now_z() { date -u +%Y-%m-%dT%H:%M:%SZ; }
log() { printf '%s housekeeping: %s\n' "$(now_z)" "$*" >&2; }

usage() {
  cat <<'EOF'
Usage: swarm/housekeeping.sh [--self-test]
Resolve a Pokémon identity for every unnamed model (ADR-083). Run from the repo
root. Drains the whole unnamed list (one labelled PR per Pokémon, each merged
before the next); run.sh blocks on it before starting the proving arms.
EOF
}

# --- pure helpers (hermetic; exercised by --self-test) --------------------

# Deterministic, URL-safe slug for a provider/model — mirrors the Python
# slugify so the branch name and the registry slug agree.
registry_slug() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//'
}

branch_name() { printf 'chore/registry-%s' "$(registry_slug "$1")"; }

commit_subject() { printf 'chore(registry): name %s as %s' "$1" "$2"; }

# The naming model in provider_model form, so the frontend can show that model's
# own Pokémon ("named by model/Pokémon"). The housekeeping agent is the `claude`
# CLI, so provider=claude, model=$1.
named_by_model() { printf 'claude / %s' "$1"; }

# The research + selection brief handed to the agent. $1 provider/model,
# $2 comma-separated taken Pokémon names.
build_prompt() {
  local pm="$1" taken="$2"
  cat <<EOF
You are a swarm operational agent performing a model-naming work package
(ADR-083). Research the model identified as "${pm}" and assign it ONE Pokémon.

1. RESEARCH the model using web tools. Determine: whether it is open or closed
   source (use "open"/"closed", or "n/a" if it is a tactic/library/artifact, not
   a model); the publisher; the country of origin; the parameter size (e.g.
   "70B", or "undisclosed", or "n/a"); the licence; and a canonical_url — the
   Hugging Face model page if open-source, otherwise the official product
   website. For a library or tactic, link its canonical repository.

2. CHOOSE one Pokémon that fits the model's character, capability and origin.
   It MUST be a real Pokémon and MUST NOT be any of these already-taken names:
   ${taken:-(none yet)}.
   Give its name and national Pokédex id. Justify the choice.

3. Respond with ONLY this JSON object. Your ENTIRE reply MUST start with "{" and
   end with "}" — no preamble, no explanation, no markdown fences. Keep it
   COMPACT so the JSON is complete and valid: each research value at most ~8
   words; "profile" at most 2 short sentences; at most 3 sources.
   {
     "pokemon": {"name": "<Name>", "dex_id": <int>},
     "research": {
       "classification": "open|closed|n/a",
       "publisher": "...", "country": "...", "parameter_size": "...",
       "license": "...", "canonical_url": "https://..."
     },
     "profile": "<<=2 sentences on why this Pokémon represents this model>",
     "sources": ["https://...", "https://..."]
   }
Do not include the sprite_url or description — those are filled deterministically.
EOF
}

run_self_test() {
  local rc=0
  [ "$(registry_slug 'claude / opus')" = 'claude-opus' ] || { echo "registry_slug FAIL" >&2; rc=1; }
  [ "$(registry_slug 'openai / Leanstral-2603-GGUF')" = 'openai-leanstral-2603-gguf' ] || { echo "registry_slug FAIL2" >&2; rc=1; }
  [ "$(branch_name 'claude / opus')" = 'chore/registry-claude-opus' ] || { echo "branch_name FAIL" >&2; rc=1; }
  [ "$(commit_subject 'claude / opus' 'Alakazam')" = 'chore(registry): name claude / opus as Alakazam' ] || { echo "commit_subject FAIL" >&2; rc=1; }
  [ "$(named_by_model 'opus')" = 'claude / opus' ] || { echo "named_by_model FAIL" >&2; rc=1; }
  build_prompt 'x / y' 'Ditto, Abra' | grep -q 'Ditto, Abra' || { echo "build_prompt taken FAIL" >&2; rc=1; }
  [ "$rc" -eq 0 ] && echo "housekeeping self-test: OK" >&2
  return "$rc"
}

# --- live helpers (network / git / gh) ------------------------------------

# Owning swarm contributor: the operator's GitHub handle, mirroring how the
# prover resolves the solver. UNSORRY_SOLVER wins; else the gh-authenticated
# user; else git config; else "unknown".
resolve_contributor() {
  local c="${UNSORRY_SOLVER:-}"
  [ -n "$c" ] || c="$(gh api user --jq .login 2>/dev/null || true)"
  [ -n "$c" ] || c="$(git config user.name 2>/dev/null || true)"
  printf '%s' "${c:-unknown}"
}

taken_names() {
  python3 -c "import json;from tools.model_registry import registry as r;print(', '.join(sorted(r.taken_names(r.load_registry('$REGISTRY')))))"
}

# Is $1 (a provider/model) present in origin/<base>'s registry yet?
model_landed() {
  git show "origin/$BASE_BRANCH:$REGISTRY" 2>/dev/null \
    | python3 -c "import sys,json;d=json.load(sys.stdin);sys.exit(0 if '$1' in {m['provider_model'] for m in d.get('models',[])} else 1)" 2>/dev/null
}

# Return the first JSON object from the agent's reply. Uses `-c` (NOT `- <<EOF`)
# so the piped reply stays on stdin — a heredoc would itself BE python's stdin
# and the piped reply would be discarded (sys.stdin.read() → empty). raw_decode
# parses correctly through braces inside strings and rejects a truncated object.
extract_json() {
  # shellcheck disable=SC2016  # the program is literal; $ must not be expanded
  python3 -c '
import json, re, sys
text = sys.stdin.buffer.read().decode("utf-8", "replace")
text = re.sub(r"^\s*```(?:json)?\s*|\s*```\s*$", "", text.strip(), flags=re.MULTILINE)
start = text.find("{")
if start == -1:
    sys.exit(1)
try:
    obj, _ = json.JSONDecoder().raw_decode(text[start:])
except ValueError:
    sys.exit(1)
sys.stdout.buffer.write(json.dumps(obj, ensure_ascii=False).encode("utf-8"))
sys.exit(0)
'
}

# Research + write the entry for $1; on success leaves REGISTRY modified in the
# working tree and echoes the chosen Pokémon name. Returns 1 if it cannot.
research_and_write() {
  local pm="$1" taken prompt raw candidate tmp attempt
  taken="$(taken_names)"
  tmp="$(mktemp -d)"
  candidate="$tmp/candidate.json"
  for attempt in $(seq 1 "$RETRIES"); do
    prompt="$(build_prompt "$pm" "$taken")"
    raw="$(timeout "$WALL" claude -p "$prompt" --model "$MODEL" \
      --output-format text --allowedTools "WebSearch,WebFetch,Read" \
      </dev/null 2>"$tmp/err.log" || true)"
    if [ -z "$raw" ]; then
      log "attempt $attempt: empty agent response for '$pm' (stderr: $(tr '\n' ' ' < "$tmp/err.log" | tail -c 300))"
      continue
    fi
    if ! printf '%s' "$raw" | extract_json > "$candidate"; then
      log "attempt $attempt: no JSON object for '$pm' (raw head: $(printf '%s' "$raw" | tr '\n' ' ' | head -c 220))"
      continue
    fi
    if python3 -m tools.model_registry assign \
        --registry "$REGISTRY" --provider-model "$pm" --candidate "$candidate" \
        --assigned-by "$AGENT_ID" --assigned-with "$(named_by_model "$MODEL")" \
        --contributor "$CONTRIBUTOR" --assigned-at "$(now_z)" >/dev/null; then
      # Echo ONLY the Pokémon name (assign's "OK" was sent to /dev/null) so the
      # caller's commit/PR title isn't polluted.
      python3 -c "import json;print(json.load(open('$candidate'))['pokemon']['name'])"
      rm -rf "$tmp"; return 0
    fi
    log "attempt $attempt: candidate for '$pm' failed validation; retrying"
  done
  rm -rf "$tmp"
  return 1
}

# Branch, commit, push and open one labelled PR for the staged registry change.
open_pr() {
  local pm="$1" poke="$2" branch="$3"
  # The branch name carries a per-attempt unique suffix (see name_one), so it
  # never collides with a leftover or a *concurrent* runner's branch — no
  # delete-then-push (which would clobber another runner mid-flight).
  git checkout -B "$branch" >/dev/null
  git add "$REGISTRY"
  git commit -m "$(commit_subject "$pm" "$poke")" \
    -m "Assign the Pokémon identity for \`$pm\` (ADR-083). One Pokémon per PR." >/dev/null
  git push -u origin "$branch" >/dev/null
  gh pr create --base "$BASE_BRANCH" --head "$branch" \
    --label model-registry --label chore \
    --title "$(commit_subject "$pm" "$poke")" \
    --body "Names \`$pm\` as **$poke** in the model → Pokémon registry (ADR-083). Validated by the model-registry gate (schema · uniqueness · one-Pokémon-per-PR)." \
    >/dev/null
  gh pr merge "$branch" --squash --auto >/dev/null 2>&1 || true  # auto-merge if the repo allows
}

# Block until $pm lands on main (by THIS PR or any concurrent runner's), then
# re-sync. Nudges the merge each poll (GitHub still gates on required checks), so
# it works whether or not repo-level auto-merge is enabled. If the model was
# named by another runner, our now-redundant PR is closed.
settle_pr() {
  local pm="$1" branch="$2"
  for _ in $(seq 1 "$SETTLE_TRIES"); do
    git fetch -q origin "$BASE_BRANCH" 2>/dev/null || true
    if model_landed "$pm"; then
      # If our PR lost the race it's still open with a now-duplicate entry the
      # gate rejects — close it (a no-op if ours is the one that merged).
      gh pr close "$branch" --delete-branch >/dev/null 2>&1 || true
      git checkout -q "$BASE_BRANCH"
      git reset --hard -q "origin/$BASE_BRANCH"
      git branch -D "$branch" >/dev/null 2>&1 || true
      return 0
    fi
    gh pr merge "$branch" --squash --delete-branch >/dev/null 2>&1 || true
    sleep "$SETTLE_WAIT"
  done
  log "timed out waiting for '$pm' (PR $branch) to merge"
  return 1
}

# Name one model end-to-end: research → PR → settle onto main.
name_one() {
  local pm="$1" poke branch
  # Per-attempt unique suffix so concurrent runners (and abandoned earlier runs)
  # never share a branch name. The PR title/commit stay clean (slug only).
  branch="$(branch_name "$pm")-$$-${RANDOM}"
  if ! poke="$(research_and_write "$pm")"; then
    git checkout -- "$REGISTRY" 2>/dev/null || true
    log "could not research/validate a Pokémon for '$pm'"
    return 1
  fi
  open_pr "$pm" "$poke" "$branch"
  if ! settle_pr "$pm" "$branch"; then
    return 1
  fi
  log "named '$pm' as $poke — landed on $BASE_BRANCH"
  return 0
}

# Put the checkout on an up-to-date, clean BASE_BRANCH before naming, so each
# per-model branch is cut from origin/<base> even if run.sh left us on a stale
# branch (e.g. a previous feature branch). Refuses to clobber tracked changes.
sync_base() {
  git fetch -q origin "$BASE_BRANCH" 2>/dev/null || return 1
  git diff --quiet && git diff --cached --quiet || return 1
  git checkout -q -B "$BASE_BRANCH" "origin/$BASE_BRANCH"
}

# Force the checkout back to an up-to-date BASE_BRANCH at the top of every naming
# cycle, discarding our own transient registry edit. This is what makes
# CONCURRENT runners cooperate: each cycle re-reads what others have merged, so a
# runner only ever attempts a genuinely-unnamed model (it won't keep re-picking
# Pokémon another operator already found).
goto_clean_base() {
  git checkout -q -- . 2>/dev/null || true
  git checkout -q "$BASE_BRANCH" 2>/dev/null || true
  git fetch -q origin "$BASE_BRANCH" 2>/dev/null || true
  git reset --hard -q "origin/$BASE_BRANCH" 2>/dev/null || true
}

main() {
  case "${1:-}" in
    -h|--help) usage; exit 0 ;;
    --self-test) run_self_test; exit $? ;;
  esac

  [ -f "$REGISTRY" ] || { log "registry $REGISTRY missing — run from repo root"; exit 2; }
  [ -f tools/model_registry/__main__.py ] || { log "run from the repository root"; exit 2; }
  if [ ! -f "$DISTRIBUTION" ]; then
    log "no $DISTRIBUTION yet — leaderboard not generated; nothing to do"; exit 0
  fi
  if ! sync_base; then
    log "could not sync to a clean $BASE_BRANCH (uncommitted tracked changes, or no network) — aborting before naming"
    exit 2
  fi

  CONTRIBUTOR="$(resolve_contributor)"
  log "owning swarm contributor: $CONTRIBUTOR; naming model: $(named_by_model "$MODEL")"

  local named=0 misses=0 pm
  local cap_misses="${UNSORRY_REGISTRY_MAX_MISSES:-8}"
  while [ "$MAX" -le 0 ] || [ "$named" -lt "$MAX" ]; do
    # Re-sync to main, then pick a RANDOM unnamed model. Both points let multiple
    # run.sh operators cooperate: the re-sync drops models others just named, and
    # the random pick keeps two runners from lock-stepping on the same model.
    goto_clean_base
    pm="$(python3 -m tools.model_registry unassigned \
      --distribution "$DISTRIBUTION" --registry "$REGISTRY" | shuf | head -n1)"
    if [ -z "$pm" ]; then
      [ "$named" -eq 0 ] && log "every model already has a Pokémon — nothing to do"
      break
    fi
    if name_one "$pm"; then
      named=$((named + 1)); misses=0
    else
      # A lost race or a transient failure — skip and try another model rather
      # than aborting (another runner likely took this one).
      misses=$((misses + 1))
      log "did not land '$pm' (another runner may have taken it) — skipping [$misses/$cap_misses]"
      [ "$misses" -ge "$cap_misses" ] && { log "too many consecutive misses — stopping"; break; }
    fi
  done

  # Guarantee check: every distribution model must have a Pokémon (named by any
  # runner) before run.sh starts proving. Re-sync first so we count what's truly
  # on main.
  goto_clean_base
  if [ -n "$(python3 -m tools.model_registry unassigned \
      --distribution "$DISTRIBUTION" --registry "$REGISTRY")" ]; then
    log "some models are still unnamed (named $named here); re-run to finish"
    return 1
  fi
  log "every distribution model now has a Pokémon (named $named here this run)"
}

main "$@"
