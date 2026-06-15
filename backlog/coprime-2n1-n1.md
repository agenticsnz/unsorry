# coprime-2n1-n1

2n+1 and n+1 are coprime for every n.

- **Source:** #400 Identity Engine (ADR-043) — gcd-coprime family.
- **Reference:** 2n+1 and n+1 are coprime for every n. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14).
- **Difficulty:** 3
- **Decomposition sketch:** gcd divides 2(n+1)=2n+2 and 2n+1, hence divides their difference 1.
