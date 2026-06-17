# The four sourcing gates (full detail)

The pipeline is SPEC-043-A §1 / ADR-035 / ADR-012. Each gate is a tool; the value
is in reading its exit code correctly. A gate you skip or paper over poisons the
backlog with a duplicate or a triviality — the whole point of sourcing is that the
backlog stays *honest*.

## Gate 1 — Absence (`tools.sourcing.check_absence`)

```bash
python3 -m tools.sourcing.check_absence --pattern '<regex>' [--pattern '<regex>' ...] \
    [--loogle '<query>'] [--mathlib <dir>] [--rev <sha>] --json
```

- `--pattern` (repeatable, ≥1 required): a regex that *would* match the theorem if
  mathlib already stated it. Grep is over the pinned mathlib at
  `.lake/packages/mathlib/Mathlib`.
- **Exit `0`** → `verdict: "no-local-match"` — admit. **Record `mathlib_rev`** from
  the JSON; absence is rev-dated and has a shelf life (a mathlib bump can turn a
  target into a duplicate — that is correct, not a bug).
- **Exit `1`** → `verdict: "possible-duplicate"` — a pattern matched; read the
  printed hits, then drop or re-scope.
- **Exit `2`** → usage/error (no `--pattern`, mathlib not found).
- This is a **name-grep pre-filter**. It cannot see a lemma stated under a
  different name — gate 3 (full-Mathlib `simp`/`aesop`) is the semantic complement.
- `--loogle` is best-effort corroboration; a timeout returns `loogle_reachable:
  false` and the grep verdict stands.

Deepen absence for known lemma families with a direct grep before trusting it:
`fib_dvd`, `fib_two_mul`, `succ_mul_centralBinom_succ`, Vandermonde
`Nat.add_choose_eq`, `Nat.sum_range_choose(_sq)`, `stirlingSecond`, `add_pow`, and
the `(x±y) ∣ (xⁿ±yⁿ)` factorization witnesses.

## Gate 2 — Statement type-checks

Write `goals/<slug>.lean` (see triple-format.md) and:

```bash
lake build UnsorryGoals
```

If it does not elaborate, the statement is malformed or mis-typed — fix it. A
statement that does not type-check is not a goal. (Never build mathlib from
source; `lake exe cache get` fetches the binary cache — ADR-002.)

## Gate 3 — Non-triviality (`tools.sourcing.check_triviality`)

```bash
python3 -m tools.sourcing.check_triviality goals/<slug>.lean [--per-tactic] [--json]
```

Builds a probe that states the goal's closed type under `import Mathlib` and tries
the fixed battery:

```
rfl · trivial · decide · norm_num · omega · simp · simp_all · aesop · ring · linarith · tauto
```

Verdict → exit code (the `_EXIT` map):

| verdict | exit | meaning |
|---|---|---|
| `non-trivial` | 0 | elaborated, nothing closed it — **admit-eligible** |
| `allowlisted` | 0 | on `tools/sourcing/triviality_allowlist.txt` — admit (intentional fixtures) |
| `override` | 0 | `- **Nontrivial-override:** <reason>` present in `backlog/<slug>.md` — admit |
| `trivial` | 1 | a battery tactic closed it (one-shot, or a renamed mathlib dup) — **drop** |
| `probe-error` | 2 | the statement failed to elaborate — **a tooling gap to FIX, never admit** |

Critical: **exit 2 is not a pass.** A `probe-error` means the probe could not even
state your theorem (unknown identifier, missing import). Fix the statement/imports
and re-run; admitting on a probe-error smuggles in an unscreened goal.

`native_decide` and `nlinarith/positivity/field_simp/gcongr` are **deliberately
excluded** from the battery (ADR-035) — so goals those tactics would close survive
as legitimately hard. That exclusion is a *feature* you exploit for difficulty
(see themes-and-difficulty.md), not a loophole to file `nlinarith`-trivial goals;
if you can close it in one `nlinarith`, it is not hard — drop it yourself.

## Gate 4 — Provable + adversarial skeptic

- **Provable-compile:** assemble the *intended* proof in a scratch file
  (`import Mathlib` + the theorem, proof filled in) and `lake env lean <scratch>`
  from the repo root. ~5% of candidates drop here; that is a signal, not a
  failure. (For the lightweight fork path you may defer this to CI — see
  fork-contributor-path.md.)
- **Skeptic:** run agents/skeptic.md — an independent pass that tries to show the
  statement is a disguised named mathlib lemma or an over-general/vacuous form. Any
  finding must be backed by a re-runnable gate-1 or gate-3 check, not vibes.

Only a candidate that clears all four gates becomes a promoted triple.
