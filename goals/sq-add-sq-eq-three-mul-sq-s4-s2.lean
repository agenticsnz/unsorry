import Mathlib

theorem integer_triple_descent_forbids_nonzero (P : ℤ → ℤ → ℤ → Prop) (desc : ∀ x y z, P x y z → x ≠ 0 ∨ y ≠ 0 ∨ z ≠ 0 → ∃ x1 y1 z1, P x1 y1 z1 ∧ Int.natAbs x1 + Int.natAbs y1 + Int.natAbs z1 < Int.natAbs x + Int.natAbs y + Int.natAbs z) : ∀ x y z, P x y z → ¬ (x ≠ 0 ∨ y ≠ 0 ∨ z ≠ 0) := by
  sorry
