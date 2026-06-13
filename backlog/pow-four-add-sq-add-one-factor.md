# pow-four-add-sq-add-one-factor

For every integer n, n⁴ + n² + 1 = (n² + n + 1)(n² − n + 1); the classic Aurifeuillian-style factorization of x⁴+x²+1 (a product of the two "cyclotomic-like" quadratics).

- **Source:** classic identities (compositeness-via-factorization — the factorization leaf)
- **Reference:** Standard algebra: x⁴+x²+1 = (x²+1)²−x² = (x²+x+1)(x²−x+1). Appears throughout olympiad number theory as the lever for showing n⁴+n²+1 is composite. Engel, Problem-Solving Strategies; Andreescu & Andrica, Number Theory.
- **Absence:** machine-checked no-local-match (grep of pinned mathlib rev c5ea00351c28, 2026-06-13); mathlib's `Algebra/Ring/Identities` has the Sophie Germain a⁴+4b⁴ and Brahmagupta identities but not this one.
- **Difficulty:** 2
- **Decomposition sketch:** A polynomial identity over ℤ — `ring` closes it directly. 1 step. Feeds the compositeness corollary `pow-four-add-sq-add-one-not-prime`.
