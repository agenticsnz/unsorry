import Mathlib

open Nat Set

theorem putnam_2005_a3 (p : Polynomial ℂ)
    (n : ℕ)
    (hn : 0 < n)
    (g : ℂ → ℂ)
    (pdeg : p.degree = n)
    (pzeros : ∀ z : ℂ, p.eval z = 0 → ‖z‖ = 1)
    (hg : ∀ z : ℂ, g z = (p.eval z) / z ^ ((n : ℂ) / 2))
    (z : ℂ)
    (hz : z ≠ 0 ∧ DifferentiableAt ℂ g z ∧ deriv g z = 0) :
    ‖z‖ = 1 := by
  sorry
