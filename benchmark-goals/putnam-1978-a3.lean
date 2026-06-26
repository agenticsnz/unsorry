import Mathlib

open Set Polynomial
abbrev putnam_1978_a3_solution : ℕ := 2

theorem putnam_1978_a3 (p : Polynomial ℝ)
    (hp : p = 2 * (X ^ 6 + 1) + 4 * (X ^ 5 + X) + 3 * (X ^ 4 + X ^ 2) + 5 * X ^ 3)
    (I : ℕ → ℝ)
    (hI : I = fun k ↦ ∫ x in Ioi 0, x ^ k / p.eval x) :
    IsLeast {y | ∃ k ∈ Ioo 0 5, I k = y} (I putnam_1978_a3_solution) := by
  sorry
