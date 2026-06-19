# cube-mod-fortythree-mem

The cubic residues modulo the prime 43 are exactly the fifteen values {0,1,2,4,8,11,16,21,22,27,32,35,39,41,42}.

- **Source:** #400 Identity Engine (ADR-043) — power-residue family; promoted from candidate backlog.
- **Reference:** The cubic residues modulo the prime 43 are exactly the fifteen values {0,1,2,4,8,11,16,21,22,27,32,35,39,41,42}. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_dvd).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 3
- **Decomposition sketch:** 3 | 42 so only 15 cubic residues occur; Nat.pow_mod plus decide over n % 43 with raised maxRecDepth. Verified to build (lake env lean) at sourcing.
