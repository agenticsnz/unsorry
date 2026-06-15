# The Identity Engine — program charter (#400, ADR-043)

> **BHAG:** be the first autonomous system to mass-produce kernel-checked, **mathlib-absent**,
> non-trivial elementary identities & inequalities at scale (hundreds → thousands),
> upstream-targeted. The swarm proves them; the kernel judges; every merged lemma makes the
> next cheaper. This is the productization of #400's "Phase-3 library growth" into a named,
> scaled, upstream-oriented program.

## Why this, and the directions not taken

| Direction | Headline | Scale | Swarm-fit / provability | Verdict |
|-----------|----------|-------|--------------------------|---------|
| **Identity Engine** | first to mass-produce mathlib-absent identities, upstream-targeted | hundreds→thousands | **High** — the swarm's proven sweet spot | **chosen** |
| Crack an AI benchmark | beat machine SOTA on PutnamBench / miniF2F-v2 | ~650 / ~500 | Medium — many need olympiad insight; fewer ship | future pivot |
| Formalize a Classic | first full Lean formalization of *Concrete Mathematics* | hundreds | High but capped to one artifact | anchor, folded in |

Corpus anchors for legibility & upstreaming: *Concrete Mathematics* (Graham–Knuth–Patashnik),
the OEIS closed-form identities, and the Lean community's `100-missing` / `1000+ theorems` /
`undergrad_todo` lists.

## The ten themes

| # | Theme | Proof engine | Example shapes |
|---|-------|--------------|----------------|
| 1 | Binomial / central-binomial | induction + `Finset.sum_range_succ` | `∑ C(k,2)=C(n+1,3)`, `∑ C(n,k)²=C(2n,n)` |
| 2 | Fibonacci / Lucas | induction | (careful — mathlib coverage is strong; mine the gaps) |
| 3 | Divisibility (ZMod-decide) | `decide` over `ZMod k` | `6∣n³+5n`, `120∣5-consecutive` |
| 4 | Power-residue / modular | `Nat.pow_mod` + `interval_cases` + `decide` | `n³%9∈{0,1,8}`, `n⁵%11∈{0,1,10}` |
| 5 | Telescoping sums / products | induction + `field_simp`/`ring` | `∑ 1/((k+1)(k+2))=n/(n+1)` |
| 6 | Figurate numbers | induction | Nicomachus family, `∑(2k+1)²` |
| 7 | Classical 2–3 var inequalities (SOS) | `nlinarith [sq_nonneg …]` | `ab+bc+ca≤a²+b²+c²`, Cauchy-3 |
| 8 | GCD / coprimality / Euclidean | `Nat.gcd`/`Nat.Coprime` lemmas | `gcd a b · lcm a b = a·b` |
| 9 | Concrete-Math / OEIS closed forms | induction | geometric sums, partial-sum identities |
| 10 | Polynomial / algebraic identities | `ring` behind a binder | Brahmagupta–Fibonacci, Sophie Germain |

Reserve themes (candidate-backlog only, lower confidence): continued-fraction / Pell,
partition / generating-function coefficients.

## The first 100 (split)

| Track | Count | Notes |
|-------|-------|-------|
| A — unblock blocked goals | ~12 | decomposition subs for the 4 blocked goals (mostly already sourced; swarm proving) |
| B — Freek #50 / #365 | ~5 | already sourced; carried to *proved* (Track-2 geometric stays mathlib-blocked, ADR-031) |
| C — Identity Engine | ~83 | mined across the ten themes; the rest staged into `backlog/candidates/` |

## Progress (updated per batch)

**Shipped: 8 / 100 · Sourced & in-flight: 59 / 100 · Scoped: 259 / 200 ✓ · mathlib c5ea00351c**

| Theme | sourced | target (first-100) |
|-------|---------|--------------------|
| divisibility (3) | 2 | 12 |
| power-residue (4) | 2 | 12 |
| telescoping (5) | 2 | 12 |
| binomial (1) | 0 | 10 |
| fibonacci (2) | 0 | 6 |
| figurate (6) | 0 | 8 |
| inequalities (7) | 0 | 10 |
| gcd/coprime (8) | 0 | 6 |
| closed-form sums (9) | 0 | 8 |
| algebraic (10) | 0 | 6 |

Batch log:
- **#577** — batch 1, +6 (divisibility ×2, power-residue ×1, telescope ×2, 5-consecutive ×1).
- **#581** — batch 2, +8 (divisibility, residue, figurate) — **merged**.
- **#582** — batch 3, +29 (6 themes).
- **#584** — batch 4, +16 (residue, gcd/coprime, modular, not-prime).
- **candidate backlog** — +259 vetted-but-not-sourced across all 12 themes (absence-clean +
  ADR-035 non-trivial; promotion runs the `lake env lean` + skeptic gates).

Candidate backlog (the "planned" half, ≥200 bar **met**): binomial 20 · fibonacci 20 ·
zmod-divisibility 22 · power-residue 24 · telescoping 22 · figurate 24 · sos-inequalities 20 ·
gcd-coprime 23 · concrete-math 21 · algebraic-identities 20 · continued-fraction-pell 24 ·
partition-genfun 18.

See `backlog/candidates/` for the staged candidates, `docs/targets.md` for the live board, and
#81 for the per-batch announcements.
