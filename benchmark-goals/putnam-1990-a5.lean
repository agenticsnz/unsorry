import Mathlib

open Filter Topology Nat
abbrev putnam_1990_a5_solution : Prop := False

theorem putnam_1990_a5 :
  putnam_1990_a5_solution ↔
  (∀ n ≥ 1, ∀ A B : Matrix (Fin n) (Fin n) ℝ,
    A * B * A * B = 0 → B * A * B * A = 0) := by
  sorry
