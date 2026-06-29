import Mathlib

open  Real Equiv Polynomial Filter Topology
abbrev putnam_1986_b4_solution : Prop := True

theorem putnam_1986_b4 (G : ℝ → ℝ)
(hGeq : ∀ r : ℝ, ∃ m n : ℤ, G r = |r - sqrt (m ^ 2 + 2 * n ^ 2)|)
(hGlb : ∀ r : ℝ, ∀ m n : ℤ, G r ≤ |r - sqrt (m ^ 2 + 2 * n ^ 2)|)
: (Tendsto G atTop (𝓝 0) ↔ putnam_1986_b4_solution) := by
  sorry
