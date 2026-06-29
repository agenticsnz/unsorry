import Mathlib

theorem putnam_1980_a5 (P : Polynomial ℝ)
    (Pnonconst : P.degree > 0) :
    Set.Finite {x : ℝ |
      0 = (∫ t in (0)..x, P.eval t * Real.sin t) ∧
      0 = (∫ t in (0)..x, P.eval t * Real.cos t)} := by
  sorry
