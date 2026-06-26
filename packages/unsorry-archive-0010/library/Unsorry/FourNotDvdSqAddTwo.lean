import Mathlib.Data.ZMod.Basic

/-!
# `4` never divides `n ^ 2 + 2`

A square is congruent to `0` or `1` modulo `4`, so `n ^ 2 + 2` is congruent to
`2` or `3` modulo `4` and is therefore never a multiple of `4`. We carry this
case analysis out by transporting the divisibility statement into `ZMod 4`,
where it becomes a finite, decidable check.
-/

theorem four_not_dvd_sq_add_two (n : ℤ) : ¬ (4 : ℤ) ∣ (n ^ 2 + 2) := by
  intro h
  have h' : ((4 : ℕ) : ℤ) ∣ (n ^ 2 + 2) := by exact_mod_cast h
  rw [← ZMod.intCast_zmod_eq_zero_iff_dvd] at h'
  push_cast at h'
  have key : ∀ m : ZMod 4, m ^ 2 + 2 ≠ 0 := by decide
  exact key _ h'
