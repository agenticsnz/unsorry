# sq-mod-seven

For every natural n, n² % 7 ∈ {0,1,2,4} (quadratic residues mod 7).

- **Source:** #400 Identity Engine (ADR-043) — power-residue family.
- **Reference:** For every natural n, n² % 7 ∈ {0,1,2,4} (quadratic residues mod 7). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14).
- **Difficulty:** 2
- **Decomposition sketch:** Nat.pow_mod; interval_cases (n%7); decide. Verified to build (lake env lean).
