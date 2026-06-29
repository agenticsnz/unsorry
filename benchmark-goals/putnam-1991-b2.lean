import Mathlib

open Filter Topology

theorem putnam_1991_b2 (f g : ℝ → ℝ)
  (fgnconst : ¬∃ c, f = Function.const ℝ c ∨ g = Function.const ℝ c)
  (fgdiff : Differentiable ℝ f ∧ Differentiable ℝ g)
  (fadd : ∀ x y, f (x + y) = f x * f y - g x * g y)
  (gadd : ∀ x y, g (x + y) = f x * g y + g x * f y) :
  (deriv f 0 = 0) → (∀ x, (f x) ^ 2 + (g x) ^ 2 = 1) := by
  sorry
