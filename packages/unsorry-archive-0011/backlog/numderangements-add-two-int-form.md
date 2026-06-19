# numderangements-add-two-int-form

The derangement count of an (n+2)-set is (n+1) times the sum of the derangement counts of the (n+1)- and n-element sets, stated over the integers.

- **Source:** #400 Identity Engine (ADR-043) — partition/generating-function family; promoted from candidate backlog.
- **Reference:** The derangement count of an (n+2)-set is (n+1) times the sum of the derangement counts of the (n+1)- and n-element sets, stated over the integers. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-15); generic-lemma instances dropped via direct mathlib grep (sub_dvd_pow_sub_pow / Odd.add_dvd_pow_add_pow / add_pow / centralBinom / Vandermonde / fib_dvd).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-15).
- **Difficulty:** 2
- **Decomposition sketch:** Push numDerangements_add_two through the integer cast with push_cast / Nat.cast_add; needs the defining recurrence rewrite rather than any battery tactic. Verified to build (lake env lean) at sourcing.
