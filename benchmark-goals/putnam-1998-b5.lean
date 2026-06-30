import Mathlib

open Set Function Metric
abbrev putnam_1998_b5_solution : ℕ := 1

theorem putnam_1998_b5 (N : ℕ)
(hN : N = ∑ i ∈ Finset.range 1998, 10^i)
: putnam_1998_b5_solution = (Nat.floor (10^1000 * Real.sqrt N)) % 10 := by
  sorry
