# SPEC-024-A: Cross-Cycle Lesson Memory

Implements: [ADR-024](../ADR-024-Cross-Cycle-Lesson-Memory.md) · Builds on [ADR-023](../ADR-023-Proof-Provenance-Leaderboard.md), ADR-014, ADR-016 · Status: Living · Updated: 2026-06-13

## Toggle

`UNSORRY_LESSONS` controls the whole feature. Default `1` (on). When `0`, no
lesson is read into a prompt and no lesson field is written, so a run is
byte-identical to pre-ADR-024 behaviour — this is what makes an on/off A/B
comparison clean.

## Failure-signature capture

`run_proof` already retains the last failed attempt's combined
`lake build UnsorryLibrary --wfail` / `lake exe axiom_audit` output in `err`.
When all attempts are exhausted, that text is held in `PROOF_LAST_ERROR` and
becomes the run's lesson. It is sanitised into a single AISP-legal line by the
`lesson-sig` helper:

- all whitespace (including newlines) collapses to single spaces;
- the AISP delimiters `{` `}` `;` `≜` `⟦` `⟧` `⟨` `⟩` and the quote `"` are
  removed (they would break block/field parsing or the prose-density lint);
- mathematical content that is *not* a delimiter (`⊢`, `→`, `=`, identifiers)
  is preserved, because it is the actionable part of a Lean error;
- the result is trimmed and truncated to `LESSON_SIG_MAX` characters.

A lesson is attached only to a non-`proved` outcome (`failed` or `decomposed`)
and only when the sanitised signature is non-empty. A `proved` run never carries
a `sig`, even if earlier attempts in the same run failed.

## Record surface

The terminal proof-run record (ADR-023) gains two optional, append-only fields:

```text
⟦Λ:Metrics⟧{attempts≜<int>; solve_s≜<int>; ended≜<ISO-8601-UTC>; lessons≜<n>}
⟦Δ:Lesson⟧{sig≜<sanitised-single-line-signature>}
```

- `lessons≜<n>` — the number of prior lesson signatures injected into this run's
  prove prompt. Written on every outcome (including `proved`) whenever the
  feature is on; omitted entirely when off. This is the measurement hook: it
  lets later analysis correlate "help received" with outcome.
- `⟦Δ:Lesson⟧{sig≜…}` — the run's own failure signature, as above. The block is
  unquoted, so it does not count toward the GB009 quoted-prose density and in
  fact lowers it.

Both fields are advisory telemetry. They never participate in statement hashing,
Gate A, proof status, affinity, candidate ranking, or any other trust decision.

## Surfacing into the prove prompt

Before the attempt loop, when the feature is on, `run_proof` calls the
`prove-lessons` helper against the prove worktree's `proof-runs/` directory
(which, being branched from `origin/main`, holds every merged run for the goal):

`prove-lessons <goal> <proof-runs-dir> [<cap>]`

- scans `proof-runs/<goal>.*.aisp`;
- keeps records whose outcome is `failed` or `decomposed` and that carry a
  non-empty `sig`;
- orders them by `ended` descending (most recent first);
- de-duplicates identical signatures (the same dead end hit repeatedly appears
  once);
- prints at most `cap` signatures (`LESSON_PROMPT_CAP`, default 3), one per line.

The shell wraps the result in a prompt block appended after the proved-dependency
block, instructing the prover that these are prior failed approaches for this
exact goal and should not be repeated. `PROOF_LESSONS_USED` records the count for
the `lessons≜<n>` field.

## Validation

Gate B `GB020` gains two optional checks on a proof-run record:

- if a `lessons` field is present, it must be a non-negative integer;
- if a `⟦Δ:Lesson⟧` block is present, its `sig` must be non-empty and at most
  `LESSON_SIG_MAX` characters (the durable boundedness invariant).

Absence of both is valid; historical records remain valid. The lesson surface
does not participate in any trust decision.

## Statistics compatibility

`tools.leaderboard` continues to parse proof-run records unchanged: the new
fields are ignored by existing aggregations, so counts, rates, and timings are
unaffected. The captured `lessons≜<n>` data is retained for future
lessons-on vs lessons-off effectiveness analysis, which ADR-024 leaves out of
scope until enough runs accumulate.

## Acceptance criteria

1. `lesson-sig` collapses multi-line verifier output to one bounded AISP-legal
   line, stripping delimiters while preserving Lean error content.
2. `render-run --lesson <raw>` emits a valid `⟦Δ:Lesson⟧{sig≜…}` block; with
   `--lessons-used <n>` it emits `lessons≜<n>` in the metrics block; without
   them the record is unchanged.
3. `prove-lessons` returns the most recent, de-duplicated, capped failed and
   decomposed signatures for a goal and nothing for proved-only history.
4. A `failed`/`decomposed` run records its signature; a `proved` run never does.
5. With `UNSORRY_LESSONS=0` the rendered record and the prove prompt are
   identical to pre-ADR-024 output.
6. Gate B accepts well-formed optional lesson telemetry and rejects an oversized
   signature or a non-integer `lessons` count; the leaderboard still parses a
   record that carries lesson telemetry.
