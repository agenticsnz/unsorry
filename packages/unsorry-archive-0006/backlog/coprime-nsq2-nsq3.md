# coprime-nsq2-nsq3

The consecutive values n^2+2 and n^2+3 are coprime for every n.

- **Source:** #400 Identity Engine (ADR-043) — gcd/coprimality family; promoted from candidate backlog (#610).
- **Reference:** The consecutive values n^2+2 and n^2+3 are coprime for every n. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_add).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** They are consecutive (second = first + 1), so Nat.coprime_succ_self_right after rewriting. Verified to build (lake env lean).
