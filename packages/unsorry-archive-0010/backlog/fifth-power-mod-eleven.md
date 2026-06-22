# fifth-power-mod-eleven

For every natural number n, the fifth power n⁵ is ≡ 0, 1, or 10 (mod 11) — i.e. 0 or ±1, by Fermat.

- **Source:** #400 Identity Engine (ADR-043) — power-residue family (Fermat's little theorem instance).
- **Reference:** By Fermat, n⁵ ≡ 0 or ±1 (mod 11); the residues are exactly {0,1,10}. Not a named mathlib lemma.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14).
- **Difficulty:** 2
- **Decomposition sketch:** Nat.pow_mod reduces n⁵%11 to (n%11)⁵%11; interval_cases (n%11); decide each. Verified to build (lake env lean).
