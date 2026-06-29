import Mathlib

open Filter Polynomial Topology Nat
abbrev putnam_1990_b5_solution : Prop := True

theorem putnam_1990_b5 :
    (∃ a : ℕ → ℝ, (∀ i, a i ≠ 0) ∧
      (∀ n ≥ 1, (∑ i ∈ Finset.Iic n, a i • X ^ i : Polynomial ℝ).roots.toFinset.card = n)) ↔
    putnam_1990_b5_solution := by
  sorry
