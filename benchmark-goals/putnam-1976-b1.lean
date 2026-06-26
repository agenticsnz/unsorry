import Mathlib

open Polynomial Filter Topology
abbrev putnam_1976_b1_solution : ℕ × ℕ := (4, 1)

theorem putnam_1976_b1 : Tendsto (fun n : ℕ => ((1 : ℝ)/n)*∑ k ∈ Finset.Icc (1 : ℤ) n, (Int.floor ((2*n)/k) - 2*Int.floor (n/k))) atTop
(𝓝 (Real.log putnam_1976_b1_solution.1 - putnam_1976_b1_solution.2)) := by
  sorry
