# lcm-self-succ

The lcm of n and n+1 is their product n(n+1).

- **Source:** #400 Identity Engine (ADR-043) — gcd-coprime family.
- **Reference:** The lcm of n and n+1 is their product n(n+1). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14).
- **Difficulty:** 2
- **Decomposition sketch:** Consecutive integers are coprime, so lcm = product via Nat.Coprime.lcm_eq_mul.
