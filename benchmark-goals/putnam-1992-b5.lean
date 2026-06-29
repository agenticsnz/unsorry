import Mathlib

open Topology Filter Nat Function Polynomial
abbrev putnam_1992_b5_solution : Prop := False

theorem putnam_1992_b5 (D : ℕ → ℚ)
  (hD : ∀ n, D n = Matrix.det (fun i j : Fin (n - 1) ↦ ite (i = j) ((i : ℕ) + 3 : ℚ) 1)) :
  putnam_1992_b5_solution ↔ (Bornology.IsBounded {x | ∃ n ≥ 2, D n / factorial n = x}) := by
  sorry
