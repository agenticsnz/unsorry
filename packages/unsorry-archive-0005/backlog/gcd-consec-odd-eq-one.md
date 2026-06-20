# gcd-consec-odd-eq-one

Two consecutive odd numbers 2n+1 and 2n+3 are coprime.

- **Source:** #400 Identity Engine (ADR-043) — gcd-coprime family.
- **Reference:** Two consecutive odd numbers 2n+1 and 2n+3 are coprime. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14).
- **Difficulty:** 3
- **Decomposition sketch:** gcd divides their difference 2 and divides the odd 2n+1, hence divides gcd(2,2n+1)=1.
