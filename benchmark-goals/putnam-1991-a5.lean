import Mathlib

open Filter Topology
noncomputable abbrev putnam_1991_a5_solution : ℝ := 1 / 3

theorem putnam_1991_a5 (f : Set.Icc (0 : ℝ) 1 → ℝ)
  (hf : ∀ y : Set.Icc 0 1, f y = ∫ x in Set.Ioo 0 y, Real.sqrt (x ^ 4 + (y - y ^ 2) ^ 2)) :
  IsGreatest (f '' (Set.Icc 0 1)) putnam_1991_a5_solution := by
  sorry
