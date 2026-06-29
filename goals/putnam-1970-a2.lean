import Mathlib

open Metric Set EuclideanGeometry

theorem putnam_1970_a2 (A B C D E F G : ℝ)
(hle : B^2 - 4*A*C < 0)
: ∃ δ > 0, ¬∃ x y : ℝ, x^2 + y^2 ∈ Set.Ioo 0 (δ^2) ∧
A*x^2 + B*x*y + C*y^2 + D*x^3 + E*x^2*y + F*x*y^2 + G*y^3 = 0 := by
  sorry
