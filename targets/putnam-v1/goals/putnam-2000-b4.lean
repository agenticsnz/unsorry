import Mathlib

open Topology Filter Nat Set Function

theorem putnam_2000_b4 (f : ℝ → ℝ)
(hfcont : Continuous f)
(hf : ∀ x, f (2 * x ^ 2 - 1) = 2 * x * f x)
: ∀ x, x ∈ Icc (-1) 1 → f x = 0 := by
  sorry
