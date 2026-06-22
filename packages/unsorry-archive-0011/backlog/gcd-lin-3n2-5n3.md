# gcd-lin-3n2-5n3

The linear forms 3n+2 and 5n+3 are coprime for every n.

- **Source:** #400 Identity Engine (ADR-043) — gcd-coprime family.
- **Reference:** The linear forms 3n+2 and 5n+3 are coprime for every n. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14).
- **Difficulty:** 3
- **Decomposition sketch:** g divides 5(3n+2)=15n+10 and 3(5n+3)=15n+9; their difference is 1, so g divides 1.
