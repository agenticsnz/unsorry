# coprime-succ-sq-add

n+1 is coprime to n²+n+1.

- **Source:** #400 Identity Engine (ADR-043) — gcd-coprime family.
- **Reference:** n+1 is coprime to n²+n+1. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14).
- **Difficulty:** 3
- **Decomposition sketch:** Rewrite n²+n+1 = 1 + n(n+1); then coprime_add_mul_right_right reduces to Coprime (n+1) 1.
