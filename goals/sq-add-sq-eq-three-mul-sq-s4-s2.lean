import Mathlib

theorem integer_triple_descent_minimal_positive_exists (P : ℤ → ℤ → ℤ → Prop) (x y z : ℤ) (hP : P x y z) (hpos : 0 < Int.natAbs x + Int.natAbs y + Int.natAbs z) : ∃ a b c, P a b c ∧ 0 < Int.natAbs a + Int.natAbs b + Int.natAbs c ∧ ∀ u v w, P u v w → 0 < Int.natAbs u + Int.natAbs v + Int.natAbs w → Int.natAbs a + Int.natAbs b + Int.natAbs c ≤ Int.natAbs u + Int.natAbs v + Int.natAbs w := by
  sorry
