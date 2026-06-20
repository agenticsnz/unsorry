# fourth-power-mod-fortyone-mem

The fourth-power residues modulo the prime 41 are exactly {0,1,4,10,16,18,23,25,31,37,40}.

- **Source:** #400 Identity Engine (ADR-043) — power-residue family; promoted from candidate backlog.
- **Reference:** The fourth-power residues modulo the prime 41 are exactly {0,1,4,10,16,18,23,25,31,37,40}. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_dvd).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** 4 | 40 gives only 11 quartic residues; Nat.pow_mod and decide over n % 41 with raised maxRecDepth. Verified to build (lake env lean) at sourcing.
