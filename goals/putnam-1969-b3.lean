import Mathlib

open Matrix Filter Topology Set Nat

theorem putnam_1969_b3 (T : ℕ → ℝ)
(hT1 : ∀ n : ℕ, n ≥ 1 → (T n) * (T (n + 1)) = n)
(hT2 : Tendsto (fun n => (T n)/(T (n + 1))) atTop (𝓝 1))
: Real.pi * (T 1)^2 = 2 := by
  sorry
