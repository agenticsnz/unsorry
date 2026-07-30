import Mathlib

open Topology Filter

theorem putnam_1966_a3 (x : ℕ → ℝ)
(hx1 : 0 < x 1 ∧ x 1 < 1)
(hxi : ∀ n ≥ 1, x (n + 1) = (x n) * (1 - (x n)))
: Tendsto (fun n : ℕ => n * (x n)) atTop (𝓝 1) := by
  sorry
