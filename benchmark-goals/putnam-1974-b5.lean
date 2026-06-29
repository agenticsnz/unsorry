import Mathlib

open Set Nat Polynomial Filter Topology

theorem putnam_1974_b5 : ∀ n ≥ 0, ∑ i ∈ Finset.Icc (0 : ℕ) n, (n^i : ℝ)/(Nat.factorial i) > (Real.exp n)/2 := by
  sorry
