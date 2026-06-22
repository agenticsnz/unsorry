#!/usr/bin/env bash
# swarm/housekeeping.sh — the swarm's first work package (ADR-083).
#
# A *swarm operational task*: assign each model in the leaderboard's model
# distribution a unique Pokémon identity (sprite + description + research +
# rationale), published to docs/metrics/model-registry.json for the guild
# frontend. The unit of work is ONE Pokémon for ONE model = exactly ONE PR; by
# default this names the next single unassigned model and opens one PR, so the
# single-file registry never races. run.sh calls it once before the prover arms
# start; over successive launches the registry fills in.
#
# Exit codes: 0 success / nothing to do · 1 cycle failure · 2 config error.
set -euo pipefail

REGISTRY="docs/metrics/model-registry.json"
DISTRIBUTION="docs/metrics/leaderboard-ui.json"
# How many models to name per invocation. Default 1 keeps each run to a single
# PR against the single-file registry (no concurrent edits). Operators may raise
# it; each iteration re-syncs main so a prior PR has landed first.
MAX="${UNSORRY_REGISTRY_MAX:-1}"
RETRIES="${UNSORRY_REGISTRY_RETRIES:-3}"
MODEL="${UNSORRY_MODEL:-opus}"
WALL="${UNSORRY_REGISTRY_WALL:-600}"
AGENT_ID="${UNSORRY_AGENT_ID:-housekeeping}"
BASE_BRANCH="${UNSORRY_BASE_BRANCH:-main}"

log() { printf '%s housekeeping: %s\n' "$(now_z)" "$*" >&2; }
now_z() { date -u +%Y-%m-%dT%H:%M:%SZ; }

usage() {
  cat <<'EOF'
Usage: swarm/housekeeping.sh [--self-test]
Assign Pokémon identities to unnamed models (ADR-083). Run from the repo root.
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

3. OUTPUT ONLY a single JSON object (no prose, no markdown fences) of the form:
   {
     "pokemon": {"name": "<Name>", "dex_id": <int>},
     "research": {
       "classification": "open|closed|n/a",
       "publisher": "...", "country": "...", "parameter_size": "...",
       "license": "...", "canonical_url": "https://..."
     },
     "profile": "<2-3 sentences explaining why this Pokémon represents this model>",
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
  build_prompt 'x / y' 'Ditto, Abra' | grep -q 'Ditto, Abra' || { echo "build_prompt taken FAIL" >&2; rc=1; }
  [ "$rc" -eq 0 ] && echo "housekeeping self-test: OK" >&2
  return "$rc"
}

# --- live helpers (network / git / gh) ------------------------------------

taken_names() {
  python3 -c "import json;from tools.model_registry import registry as r;print(', '.join(sorted(r.taken_names(r.load_registry('$REGISTRY')))))"
}

# Strip optional markdown fences and return the first balanced JSON object.
extract_json() {
  python3 - <<'PY'
import json, re, sys
text = sys.stdin.read()
text = re.sub(r"^\s*```(?:json)?|```\s*$", "", text.strip(), flags=re.MULTILINE)
start = text.find("{")
depth = 0
for i in range(start, len(text)):
    if text[i] == "{":
        depth += 1
    elif text[i] == "}":
        depth -= 1
        if depth == 0:
            sys.stdout.write(text[start : i + 1])
            sys.exit(0)
sys.exit(1)
PY
}

# Ask the agent for a candidate, validate-and-write it. $1 provider/model.
assign_one() {
  local pm="$1" taken prompt raw candidate tmp poke attempt
  taken="$(taken_names)"
  tmp="$(mktemp -d)"
  candidate="$tmp/candidate.json"
  for attempt in $(seq 1 "$RETRIES"); do
    prompt="$(build_prompt "$pm" "$taken")"
    raw="$(timeout "$WALL" claude -p "$prompt" --model "$MODEL" \
      --output-format text --allowedTools "WebSearch,WebFetch,Read" 2>/dev/null || true)"
    if [ -z "$raw" ]; then
      log "attempt $attempt: empty agent response for '$pm'"; continue
    fi
    if ! printf '%s' "$raw" | extract_json > "$candidate"; then
      log "attempt $attempt: no JSON object in response for '$pm'"; continue
    fi
    if python3 -m tools.model_registry assign \
        --registry "$REGISTRY" --provider-model "$pm" --candidate "$candidate" \
        --assigned-by "$AGENT_ID" --assigned-with "$MODEL" --assigned-at "$(now_z)"; then
      poke="$(python3 -c "import json;print(json.load(open('$candidate'))['pokemon']['name'])")"
      rm -rf "$tmp"
      _open_pr "$pm" "$poke"
      return 0
    fi
    log "attempt $attempt: candidate for '$pm' failed validation; retrying"
  done
  rm -rf "$tmp"
  git checkout -- "$REGISTRY" 2>/dev/null || true
  return 1
}

# Branch, commit, push and open an auto-merging PR for the one new entry.
_open_pr() {
  local pm="$1" poke="$2" branch
  branch="$(branch_name "$pm")"
  git checkout -b "$branch" >/dev/null
  git add "$REGISTRY"
  git commit -m "$(commit_subject "$pm" "$poke")" \
    -m "Assign the Pokémon identity for \`$pm\` (ADR-083). One Pokémon per PR." >/dev/null
  git push -u origin "$branch" >/dev/null
  gh pr create --base "$BASE_BRANCH" --head "$branch" \
    --title "$(commit_subject "$pm" "$poke")" \
    --body "Names \`$pm\` as **$poke** in the model → Pokémon registry (ADR-083). Validated by the model-registry gate (schema · uniqueness · one-Pokémon-per-PR)." \
    >/dev/null
  gh pr merge --auto --squash "$branch" >/dev/null 2>&1 \
    || log "auto-merge not enabled for $branch (will need a manual merge)"
  git checkout "$BASE_BRANCH" >/dev/null
  log "opened PR: named '$pm' as $poke ($branch)"
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

  local named=0 pm
  while [ "$named" -lt "$MAX" ]; do
    pm="$(python3 -m tools.model_registry unassigned \
      --distribution "$DISTRIBUTION" --registry "$REGISTRY" | head -n1)"
    if [ -z "$pm" ]; then
      [ "$named" -eq 0 ] && log "every model already has a Pokémon — nothing to do"
      break
    fi
    if assign_one "$pm"; then
      named=$((named + 1))
    else
      log "could not name '$pm' this cycle; stopping"
      break
    fi
  done
  log "named $named model(s) this cycle"
}

main "$@"
