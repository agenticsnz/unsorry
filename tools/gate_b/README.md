# Gate B — in-repo validator

The deterministic hygiene validator for unsorry's AISP coordination records
(ADR-003; SPEC-003-A/B/C/D). Python 3.12, stdlib only — pytest is the sole
test-time dependency. Gate B keeps the queue clean; it carries no mathematical
authority and can never admit anything into the library (that is Gate A).

## Usage

```sh
python3 -m tools.gate_b validate <tree-root> [--at ISO8601Z] [--goals-root PATH] [--json]
```

- `--at` injects the validation clock (e.g. `2026-06-10T01:00:00Z`) — required
  for deterministic claim-freshness results; defaults to the current UTC time.
- `--goals-root` supplies a tree containing `goals/` when validating a
  claims-only tree (the claims branch), enabling goal-reference and
  phase-aware cardinality checks. Without it those checks are skipped and the
  weaker live-claim bound (≤ 2, distinct agents) applies.
- `--json` emits a deterministic, sorted, machine-readable report (the reaper
  consumes the GB013 signal from it).

Only these record directories are scanned: `goals/`, `claims/`,
`translations/`, `decompositions/`, `library/index/`, `proof-runs/`. Absent
directories are vacuously valid; `tools/`, `docs/`, `swarm/` and `.git/` are
never entered.

### Exit codes

| Code | Meaning |
|---|---|
| 0 | clean — no violations |
| 1 | violations found (one line per violation: `GBnnn <relpath>: <message>`) |
| 2 | internal/usage error (bad `--at`, missing tree root, …) |

## Violation codes

| Code | Surface | Check |
|---|---|---|
| GB001 | all records | Header line parses (`𝔸<ver>.<type>.<name>@YYYY-MM-DD`) and `γ≔unsorry.<type>` is correct; file is valid UTF-8 |
| GB002 | goals, translations, decompositions | Filename / header / `⟦Ω⟧` identity fields agree; ids match the `Id` grammar |
| GB003 | goals | Enum fields within domain: `phase`, `status`, `difficulty` (0–5) |
| GB004 | goals | `phase≡prove` ⇒ `lean` set and the file exists; `phase≡translate` ⇒ `lean≜∅` |
| GB005 | goals | `status ∈ {translated, proved}` ⇒ `sha` is 64 lowercase hex |
| GB006 | goals, library/index | `status≡proved` ⇒ `library/index/<sha>.aisp` exists; index integrity: filename stem = `sha` field = SHA-256 of the stmt |
| GB007 | goals | Every dep references an existing goal id |
| GB008 | goals | `src` path exists in the tree |
| GB009 | goals, translations, decompositions | Quoted-prose density in formal blocks ≤ 0.30 (non-whitespace chars inside `"…"` ÷ non-whitespace chars); translation `stmt` non-empty |
| GB010 | claims | Filename grammar: `<goal-id>.<agent-id>.aisp`, exactly two dots |
| GB011 | claims | Header / `⟦Ω⟧` / filename agreement; `ts` parses as ISO-8601 UTC `Z` |
| GB012 | claims | `ttl` within bounds (600 ≤ ttl ≤ 86400) |
| GB013 | claims | Claim expired at validation time (`now > ts + ttl`) — freshness report consumed by the reaper |
| GB014 | claims | Live-claim cardinality per goal within phase cap (translate ≤ 2, prove ≤ 1; ≤ 2 without `--goals-root`) |
| GB015 | claims | No two live claims on one goal by the same agent |
| GB016 | translations, decompositions, claims | Goal references resolve: translation `goal` exists and is translate-phase; decomposition `parent`/subs/edges well-formed and resolve; claim `goal` exists (with `--goals-root`) |
| GB017 | all records | Required blocks present: `⟦Ω⟧` and `⟦Ε⟧` |
| GB018 | claims | Claims on a main-shaped tree: any file under `claims/` other than `README.md` when the tree has `goals/` (claims live only on the `claims` branch, ADR-004) |
| GB019 | library/index | Optional proof-provenance block is well-formed: GitHub solver handle, agent/provider ids, token-safe model/effort, and integer attempts/solve time |
| GB020 | proof-runs | Terminal run identity, goal link, outcome, attribution, attempts, elapsed time, completion timestamp, and optional proved artifact are well-formed |

## Constants

`config.py` mirrors the swarm contract (`swarm/protocol.aisp`, SPEC-003-D);
`tests/test_contract_constants.py` asserts agreement. The contract is the
normative source — fix the mirror, never the contract.

## Tests

```sh
pytest tools/gate_b -q
```

The fixture corpus under `tests/fixtures/` is the executable spec: each
`invalid_*` tree is named for the violation it must trigger; `valid_tree/` and
`claims_valid/` must stay clean.
