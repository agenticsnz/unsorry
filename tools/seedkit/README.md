# seedkit — batch generator for kernel-verified theorem families

`tools/seedkit/` generates, validates, and queues batches of net-new,
kernel-verified Lean 4 theorems for the swarm. Every goal is proven true
*before* any file is written and is run through the full local gate pipeline;
only goals that pass are pushed, one `queued/prove/<id>/*` branch per goal, for
the scheduled dispatcher to open and auto-merge. All proofs use kernel tactics
(`decide`, `induction … ; ring` — no `native_decide`), so the axiom profile
stays `[propext, Classical.choice, Quot.sound]`.

> **This is the _fixture_ path, not sourcing.** seedkit mints goals **born
> `status≜proved`** (statement + finished proof in one artifact) to grow the
> _library_; it is deterministic template generation, **not** the demand-driven
> [`unsorry-goal-sourcing`](../../Skills/unsorry-goal-sourcing/SKILL.md) pipeline
> that produces open (`status≜open`) goals for the swarm to prove. If you were
> sent here to "source new goals", use that skill instead. Provenance and
> difficulty follow the sourcing paradigm by
> [ADR-086](../../docs/adrs/ADR-086-Seedkit-Fixture-Generation-Path.md): an
> authenticated `solver` (no anonymous fixtures), the honest Lean engine
> (`provider≜lean`, `model≜decide`/`ring`), and **difficulty `1`** — these
> one-tactic / fixed-template goals sit at the bottom of the sourcing difficulty
> rubric, not the top.

## Families

Each family is a `(generator, writer)` pair plus a one-line batch wrapper. The
generator enumerates and *proves-true* candidates; the writer materialises the
[5-file artifact](#the-5-file-artifact). All families share the same gate
pipeline, push step, and record shapes (`_artifact.py`, `_words.py`).

All families rate **difficulty 1** (ADR-086): a goal closed by a single `decide`
or a fixed `induction … ; ring` is, by the sourcing skeptic's *"no short
one-tactic proof"* bar, a trivial goal — the difficulty column reflects that
honestly rather than the engine's old 3–5 self-tag.

| Family | Statement (∀ over the free variables) | Proof | Difficulty |
|---|---|---|---|
| **divisibility** (`gzmod`) | `M ∣ nᵃ − nᵇ` over `ℤ` | finite `ZMod M` `decide`, lifted via `ZMod.intCast_zmod_eq_zero_iff_dvd` | 1 |
| **residue** | `((Σ vᵢᵈ : ℤ) : ZMod m) ≠ r` (two squares, three squares, two cubes) | `push_cast`/`ring` cast, `generalize`, finite `decide` | 1 |
| **telescoping** | `∑ k∈range n, a·((k+1)ᵖ−kᵖ) = a·nᵖ` (p = 2…6) | induction on `n`; `sum_range_succ`; `push_cast`; `ring` | 1 |
| **faulhaber / geometric** | `(v−1)·∑ vᵏ = vⁿ−1`; `c·∑ kᵖ = v·poly(n)` (p = 2…5) | induction on `n`; `sum_range_succ`; `ring` | 1 |
| **arith** | `2·∑ k∈range n, (k+c) = n(n−1) + 2cn` | induction on `n`; `sum_range_succ`; `push_cast`; `ring` | 1 |
| **shiftsq** | `6·∑ k∈range n, (k+c)² = n(n−1)(2n−1) + 6c·n(n−1) + 6nc²` | induction on `n`; `sum_range_succ`; `push_cast`; `ring` | 1 |
| **oddsq** | `3·∑ k∈range n, c·(2k+1)² = c·n(2n−1)(2n+1)` | induction on `n`; `sum_range_succ`; `push_cast`; `ring` | 1 |
| **altgeom** | `(r+1)·∑ k∈range n, (−r)ᵏ = 1 − (−r)ⁿ` | induction on `n`; `sum_range_succ`; `ring` | 1 |
| **factdvd** | `(k! : ℤ) ∣ n·(n+1)·…·(n+k−1)` (k = 2…6) | finite `ZMod k!` `decide`, lifted via `ZMod.intCast_zmod_eq_zero_iff_dvd` | 1 |

The two `decide` families — `gzmod`, `residue`, `factdvd` — and `residue` are
*filtered by an exhaustive check* before emission (a residue `r` only when
unreachable; a `(M,a,b)` only when `M ∣ nᵃ−nᵇ` on every residue; `factdvd` holds
for all `k` by the consecutive-product fact), so a false statement is never
produced. The closed-form families — `telescoping`, `faulhaber`/`geometric`,
`arith`, `shiftsq`, `oddsq`, `altgeom` — are true by construction.

The coefficient/value parameter of every parametrised family is spelled as an
English word in the goal id, drawn from the shared `_words.py` table (`1..80`).

## Files

| File | Purpose |
|---|---|
| `_words.py` | shared `int → English-word` table (1…80); the single DRY source for goal-id spelling |
| `_artifact.py` | shared writer of the 5-file artifact + AISP records; validates `difficulty ∈ 0..5` (Gate B GB003) |
| `gen_gzmod.py` / `gen_gzmod_wide.py` | enumerate valid divisibility `(M,a,b)` (gap ≤ 12 / ≤ 18) |
| `mkfiles.py` / `mkfiles_wide.py` | write the artifact for one `(M,a,b)` |
| `gen_residue.py` / `mkfiles_residue.py` | residue family (`--family sum-two-squares\|sum-three-squares\|sum-two-cubes`) |
| `gen_telescoping.py` / `mkfiles_telescoping.py` | telescoping power sums (`--shape square…sextic`) |
| `gen_faulhaber.py` / `mkfiles_faulhaber.py` | geometric & Faulhaber closed forms (`--family geometric\|faulhaber-square…quintic`) |
| `gen_arith.py` / `mkfiles_arith.py` | arithmetic series (`--coeffs`, offset `c`) |
| `gen_shiftsq.py` / `mkfiles_shiftsq.py` | shifted-square sums (`--coeffs`, offset `c`) |
| `gen_oddsq.py` / `mkfiles_oddsq.py` | scaled odd-square sums (`--coeffs`, coefficient `c`) |
| `gen_altgeom.py` / `mkfiles_altgeom.py` | alternating geometric series (`--values`, ratio `r`) |
| `gen_factdvd.py` / `mkfiles_factdvd.py` | consecutive-product divisibility (`--ks`, run length `k`) |
| `split_push.sh` | one `queued/prove/<id>` branch per goal, off `origin/main`, with push retry |
| `run_batch_family.sh` | generic per-family driver: gen → write → Gate A → **per-module** build → Gate B → push → bounded build cleanup |
| `run_batch.sh` / `run_batch_wide.sh` | divisibility batch wrappers (a moduli list) |
| `run_batch_residue.sh` / `run_batch_telescoping.sh` / `run_batch_faulhaber.sh` | one-line per-family batch wrappers |
| `run_batch_arith.sh` / `run_batch_shiftsq.sh` / `run_batch_oddsq.sh` / `run_batch_altgeom.sh` / `run_batch_factdvd.sh` | one-line per-family batch wrappers (the closed-form/factorial families) |
| `run_pool.sh` | drive divisibility batches over a moduli pool to a target count |
| `topup.sh` | top up with the widened divisibility generator to a target count |
| `tests/` | import-safety + generator/writer statement-agreement regression tests |

Each generator prints one pipe-delimited line per goal; the leading fields are
exactly the positional arguments its writer takes, followed by
`id\|name\|Module\|sha`. `run_batch_family.sh` slices off those leading fields
(count = `SEEDKIT_ARGC`) to call the writer.

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
# divisibility (narrow / widened generator)
bash tools/seedkit/run_batch.sh "156"
bash tools/seedkit/run_batch_wide.sh "152"

# the other families
bash tools/seedkit/run_batch_residue.sh sum-two-squares 8
bash tools/seedkit/run_batch_telescoping.sh cube           # default coeff range
bash tools/seedkit/run_batch_faulhaber.sh faulhaber-cube
bash tools/seedkit/run_batch_faulhaber.sh geometric 2,3,5,7

# the closed-form / factorial families (single parameter; optional explicit list)
bash tools/seedkit/run_batch_arith.sh                      # default offset sweep
bash tools/seedkit/run_batch_shiftsq.sh 61,62,63,64,65
bash tools/seedkit/run_batch_oddsq.sh 31,32,33
bash tools/seedkit/run_batch_altgeom.sh 2,3,5,7            # ratio magnitudes
bash tools/seedkit/run_batch_factdvd.sh 2,3,4,5,6          # consecutive-run lengths

# drive many productive divisibility batches to a target count
bash tools/seedkit/run_pool.sh 25
bash tools/seedkit/topup.sh 12
```

Each batch prints `RESULT <label> candidates=… build=… gateb=… pushed=…`. A
batch with zero valid candidates is skipped; nothing is pushed unless `build=0`
and `gateb=0`. The working tree is reset to `origin/main` between batches.

### Per-module build

`run_batch_family.sh` validates with `lake build Unsorry.<Mod>
Unsorry.<Mod>Binding --wfail` over **only the batch's new modules**, not the
whole `UnsorryLibrary`. A fresh runner has no library oleans, so a whole-library
build recompiles ~1k modules and times out; the new modules import only Mathlib
(binary-cached) and their own statement, so a per-module build is seconds at the
same `--wfail` strictness. CI's Gate A still builds the entire library on each
`queued/prove/*` branch — this is the local pre-push gate over the changed
surface only.

### Disk hygiene

Each batch's per-module build writes `.olean`/`.c` output under `.lake/build`;
over a long pool run that output accumulates (hundreds of modules × the C file a
Mathlib-importing module emits) and can exhaust the disk. `run_batch_family.sh`
therefore runs `rm -rf .lake/build` after every batch (the mathlib binary cache
lives in `.lake/packages` and is **not** touched, so the next batch only
recompiles its own few modules). Set `SEEDKIT_CLEAN_BUILD=0` to keep the build
artifacts between batches (faster reruns, unbounded disk).

### Environment

| Variable | Default | Meaning |
|---|---|---|
| `UNSORRY_SOLVER` | — | **preferred** `solver` id (the authenticated identity). seedkit **refuses to write** if neither this nor `SEEDKIT_SOLVER` is set — no anonymous fixtures (ADR-086) |
| `SEEDKIT_SOLVER` | — | fallback `solver` id, used only when `UNSORRY_SOLVER` is unset |
| `SEEDKIT_AGENT` | `seedkit` | `agent` id in provenance and in branch/commit names |
| `SEEDKIT_BRANCH` | current branch | working branch the drivers return to |
| `SEEDKIT_BUILD_TIMEOUT` | `540` | seconds bounding each `lake build` |
| `SEEDKIT_CLEAN_BUILD` | `1` | `rm -rf .lake/build` after each batch to bound disk (set `0` to keep) |
| `SEEDKIT_GEN` / `SEEDKIT_MK` | per wrapper | generator / writer scripts (for `run_batch_family.sh`) |
| `SEEDKIT_GEN_ARGS` | per wrapper | args passed verbatim to the generator |
| `SEEDKIT_ARGC` | per wrapper | number of leading generator-line fields that are writer args |
| `SEEDKIT_LABEL` | per wrapper | token identifying the batch in the `RESULT` line |

## Choosing productive divisibility moduli

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

## Adding a family

The pipeline — prove-true-first → Gate A (`--wfail`) → Gate B → one branch per
goal → push-only — is family-agnostic. A new family needs only:

1. a **generator** (`gen_<fam>.py`) that, given args, prints
   `<writer-args…>|id|name|Module|sha` per goal, having proven each true and
   skipped existing ids;
2. a **writer** (`mkfiles_<fam>.py`) whose `write_goal(...)` builds the Lean
   statement + proof and calls `_artifact.write_artifacts(...)`;
3. a **wrapper** (`run_batch_<fam>.sh`) that sets `SEEDKIT_GEN/MK/GEN_ARGS/ARGC/
   LABEL` and execs `run_batch_family.sh`.

Reuse `_words.WORDS` for id spelling and `_artifact` for the records. Keep the
CLI behind `if __name__ == "__main__":` so a writer can import its generator's
tables without firing the enumeration — `tests/test_import_safe.py` enforces this
(and that the generator's published `sha` matches the writer's statement).

## Invariants

- Statements are proven true before any file is written — a false statement is
  never produced.
- Every goal passes Gate A (`--wfail`) and Gate B locally before it is pushed.
- One logical change per branch; branches are pushed to `queued/prove/*`, never
  directly to `main`; PRs are not opened by the kit.
- The working tree is cleaned (`git reset --hard origin/main`) between batches.
