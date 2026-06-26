# SPEC-100-A: Canonical `honest_engine` — Generator Normalization + Suffix-Tolerant Sweep

Implements: [ADR-100](../ADR-100-Normalize-Template-Engine-In-Generator.md) · Status: Living · Updated: 2026-06-26

ADR-100 closes the lag window in which a not-yet-swept deterministic-template proof
surfaces a phantom `claude/template-*` model, by folding provenance through one
canonical mapping at read time, and hardens the sweep to suffix-match template
tactics. This spec is the contract.

## 1. Deliverables

| # | Deliverable | Surface | CODEOWNERS? |
|---|---|---|---|
| D1 | `honest_engine(agent, provider, model)` canonical map | `tools/repo/relabel_attribution.py` | no |
| D2 | `relabel_record` reimplemented on `honest_engine`; `_RULES`/`_REWRITABLE_PROVIDERS` removed | same | no |
| D3 | Generator folds runs + proofs through `honest_engine` for the model distribution | `tools/leaderboard/generate.py` | **yes** (`/tools/leaderboard/` @cgbarlow) |
| D4 | Tests: `honest_engine` map + suffix tolerance + idempotence; new-shape `relabel_record`; generator fold | `tools/repo/tests/…`, `tools/leaderboard/tests/…` | no |

## 2. `honest_engine` (D1)

```python
honest_engine(agent, provider, model) -> (provider, model)
```

- `model` not starting `template-` → returns inputs unchanged (idempotent; genuine
  LLM models and already-honest engines pass through).
- `agent == "mac-158f"` → `("python", "sympy")` for any `template-*` (ADR-079/088).
- `agent in ("claude-web", "seedkit")` → `("lean","decide")` if `model` ends `decide`,
  `("lean","ring")` if it ends `ring` (ADR-086/087). **Suffix-matched** — `template-fin-decide`,
  `template-nat-induction-ring`, etc. all fold.
- Anything else (unknown agent, or unrecognised tactic under a Lean agent) → unchanged,
  surfaced rather than guessed.

## 3. Sweep (D2)

`relabel_record(text)` parses `agent`/`provider`/`model`, calls `honest_engine`, and
rewrites `provider≜`/`model≜` (each `count=1`) iff the pair changed. The literal
`_RULES` tuple and `_REWRITABLE_PROVIDERS` are removed; `_TEMPLATE_LEAN_AGENTS =
("claude-web", "seedkit")` backs `honest_engine`. `correct_solver` (ADR-099),
`correct_difficulty`, and the `index_is_*` predicates are unchanged. All prior
relabel tests stay green.

## 4. Generator (D3)

In `base_stats`, when keying `model_runs`/`model_proofs`:

```python
rp, rm = honest_engine(run.agent, run.provider, run.model)
model_runs[f"{rp} / {rm or 'unknown'}"].append(run)
# …and the proof loop, via proof.agent/provider/model
```

Per-contributor stats, difficulty, scores, and the credited/attribution paths are
untouched — only the `provider_model` distribution label is normalised. Import:
`from tools.repo.relabel_attribution import honest_engine` (pure, stdlib-only; no cycle).

## 5. Tests (D4)

- `test_relabel_attribution.py`: `honest_engine` known maps; **suffix tolerance**
  (`template-fin-decide` → lean/decide, `template-nat-induction-ring` → lean/ring,
  fresh `mac-158f` template → python/sympy); genuine/unknown/idempotent left untouched;
  `relabel_record` rewrites a never-seen template shape on disk. Existing 23 relabel
  tests unchanged.
- `test_generate.py`: a `claude/template-induction-ring` proof is counted under
  `lean / ring` (`verified_proofs == 1`) and `claude / template-induction-ring` is
  absent from the distribution.

## 6. Out of scope (follow-ups)

Suffix-tolerant `index_is_seedkit`/`index_is_mac158f` (difficulty backfill self-heals
one cycle later); de-contending the sweep's concurrency group; pruning a phantom model
already assigned a registry identity on the guild side.
