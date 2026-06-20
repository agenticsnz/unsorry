import Mathlib

theorem integer_triple_descent_fails_at_one_zero_zero : ∃ P : ℤ → ℤ → ℤ → Prop, (∀ x y z, P x y z → x ≠ 0 ∨ y ≠ 0 ∨ z ≠ 0 → ∃ x1 y1 z1, P x1 y1 z1 ∧ Int.natAbs x1 + Int.natAbs y1 + Int.natAbs z1 < Int.natAbs x + Int.natAbs y + Int.natAbs z) ∧ P 1 0 0 ∧ ¬ (1 = (0 : ℤ) ∧ (0 : ℤ) = 0 ∧ (0 : ℤ) = 0) := by
  sorry
