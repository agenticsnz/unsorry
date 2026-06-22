# seedkit — batch generator for kernel-verified divisibility theorems

`tools/seedkit/` generates, validates, and queues batches of net-new,
kernel-verified Lean 4 theorems for the swarm. The default engine produces
divisibility identities `M ∣ nᵃ − nᵇ` over `ℤ`, true for all integers `n`,
proved by a finite case check over `ZMod M` lifted through
`ZMod.intCast_zmod_eq_zero_iff_dvd`. The proof uses kernel `decide` (no
`native_decide`), so the axiom profile stays `[propext, Classical.choice,
Quot.sound]`.

Every goal is proven true *before* any file is written and is run through the
full local gate pipeline; only goals that pass are pushed, one
`queued/prove/<id>/*` branch per goal, for the scheduled dispatcher to open and
auto-merge.

## Files

| File | Purpose |
|---|---|
| `gen_gzmod.py` | enumerate valid `(M,a,b)`, prove-true, skip existing ids, print `M\|a\|b\|id\|name\|Module\|sha` (gap ≤ 12, exponents ≤ 20) |
| `gen_gzmod_wide.py` | widened generator (gap ≤ 18, exponents ≤ 30) |
| `mkfiles.py` | write the 5-file artifact for one `(M,a,b)` |
| `mkfiles_wide.py` | same, extended number-words (exponents ≤ 30) |
| `split_push.sh` | one `queued/prove/<id>` branch per goal, off `origin/main`, with push retry |
| `run_batch.sh` | one fully-gated batch for a moduli list (narrow) |
| `run_batch_wide.sh` | one fully-gated batch for a moduli list (widened) |
| `run_pool.sh` | drive batches over a moduli pool to a target count |
| `topup.sh` | top up with the widened generator to a target count |

## The 5-file artifact

| File | Contents |
|---|---|
| `goals/<id>.lean` | the statement (with `sorry`) |
| `goals/<id>.aisp` | goal record: `status≜proved`, statement `sha`, difficulty |
| `backlog/<id>.md` | human-readable description |
| `library/Unsorry/<Module>.lean` | the proof |
| `library/index/<sha>.aisp` | index record: statement `sha` + provenance |

The `<sha>` is `tools.lean_sig.statement_sha` of the canonical statement string.
The statement-binding module (`tools.gate_a.check_statement_binding generate .`)
is generated transiently for the build and is **not** committed.

## Prerequisites

- Run from the repository root with the Lean toolchain on `PATH`
  (`source $HOME/.elan/env`).
- `lake exe cache get` already run once (mathlib arrives as a binary cache;
  it is never built from source).
- The kit calls in-repo modules: `tools.lean_sig`,
  `tools.gate_a.check_statement_binding`, `tools.gate_b`.

## Usage

```bash
# one validated batch on chosen moduli (narrow generator)
bash tools/seedkit/run_batch.sh "156"

# widened generator (more candidates per modulus)
bash tools/seedkit/run_batch_wide.sh "152"

# drive many productive batches to a target count
bash tools/seedkit/run_pool.sh 25       # narrow pool
bash tools/seedkit/topup.sh 12          # add 12 more (widened)
```

Each batch prints `RESULT mods=… build=… gateb=… pushed=…`. A batch with zero
valid candidates is skipped; nothing is pushed unless `build=0` and `gateb=0`.
The working tree is reset to `origin/main` between batches.

### Environment

| Variable | Default | Meaning |
|---|---|---|
| `SEEDKIT_SOLVER` | `anon` | `solver` id stamped into each index record's provenance |
| `SEEDKIT_AGENT` | `seedkit` | `agent` id in provenance and in branch/commit names |
| `SEEDKIT_BRANCH` | current branch | working branch the drivers return to |
| `SEEDKIT_BUILD_TIMEOUT` | `540` | seconds bounding each `lake build` |

## Choosing productive moduli

A modulus `M` admits a valid `(a, b)` only when its Carmichael function `λ(M)`
divides the exponent gap `a − b`, so the gap cap bounds which moduli are
productive. Keep `M` small enough that a `decide` over `M` residues stays
CI-tractable (roughly `M ≲ 360` unless the build timeout is raised). Quick
read-only pre-filter:

```python
def valid(M, a, b): return all(pow(m, a, M) == pow(m, b, M) for m in range(M))
def yield_count(M, bmax=12, dmax=18, amax=30):
    s = set()
    for b in range(3, bmax + 1):
        for d in range(2, dmax + 1):
            a = b + d
            if 3 <= a <= amax and valid(M, a, b): s.add((a, b))
    return len(s)
# keep M with yield_count(M) >= 3 and M small enough for a CI-tractable decide
```

## Extending beyond this family

The pipeline — prove-true-first → non-trivial → Gate A (`--wfail`) → Gate B →
one branch per goal → push-only — is family-agnostic. Other families that fit
the same 5-file contract (telescoping finite-sum identities, modular
congruences, small bounded Diophantine goals closed by
`interval_cases … <;> first | decide | (exfalso; omega)`, …) can reuse
`split_push.sh` and the gate steps directly; only the generator and the proof
template change.

## Invariants

- Statements are proven true before any file is written — a false statement is
  never produced.
- Every goal is non-trivial and passes Gate A (`--wfail`) and Gate B locally.
- One logical change per branch; branches are pushed to `queued/prove/*`, never
  directly to `main`; PRs are not opened by the kit.
- The working tree is cleaned (`git reset --hard origin/main`) between batches.
