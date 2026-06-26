import Mathlib

open Finset Polynomial Topology Filter Metric

theorem putnam_1968_b4 (f : ℝ → ℝ)
(hf : Continuous f ∧ ∃ r : ℝ, Tendsto (fun y => ∫ x in ball 0 y, f x) atTop (𝓝 r))
: ∃ r : ℝ, Tendsto (fun y => ∫ x in (ball 0 y \ ball 0 (1 / y)), f (x - 1/x)) atTop (𝓝 r) ∧ Tendsto (fun y => ∫ x in ball 0 y, f x) atTop (𝓝 r) := by
  sorry
