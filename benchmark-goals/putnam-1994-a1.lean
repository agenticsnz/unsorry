import Mathlib

open Filter Topology

theorem putnam_1994_a1 (a : ℕ → ℝ)
    (ha : ∀ n ≥ 1, 0 < a n ∧ a n ≤ a (2 * n) + a (2 * n + 1)) :
    Tendsto (fun N : ℕ => ∑ n : Set.Icc 1 N, a n) atTop atTop := by
  sorry
