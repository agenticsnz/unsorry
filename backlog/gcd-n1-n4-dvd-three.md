# gcd-n1-n4-dvd-three

The gcd of n+1 and n+4 always divides 3.

- **Source:** #400 Identity Engine (ADR-043) — gcd-coprime family.
- **Reference:** The gcd of n+1 and n+4 always divides 3. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14).
- **Difficulty:** 2
- **Decomposition sketch:** gcd divides both n+1 and n+4, hence their difference (n+4)-(n+1) = 3.
