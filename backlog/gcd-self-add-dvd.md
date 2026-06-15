# gcd-self-add-dvd

The gcd of n and n+k divides k.

- **Source:** #400 Identity Engine (ADR-043) — gcd-coprime family.
- **Reference:** The gcd of n and n+k divides k. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14).
- **Difficulty:** 2
- **Decomposition sketch:** gcd divides both n and n+k, hence divides their difference (n+k)-n = k via Nat.dvd_sub.
