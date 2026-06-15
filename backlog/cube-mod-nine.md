# cube-mod-nine

For every natural number n, the cube n³ is ≡ 0, 1, or 8 (mod 9).

- **Source:** #400 Identity Engine (ADR-043) — power-residue family.
- **Reference:** The cubic residues mod 9 are exactly {0,1,8}. Not a named mathlib lemma.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14).
- **Difficulty:** 2
- **Decomposition sketch:** Nat.pow_mod reduces n³%9 to (n%9)³%9; interval_cases (n%9); decide each. Verified to build (lake env lean).
