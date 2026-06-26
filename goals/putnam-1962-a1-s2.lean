import Mathlib

theorem triangle_two_interior (a b c d e : ℝ × ℝ) (hcard : ({a, b, c, d, e} : Set (ℝ × ℝ)).ncard = 5) (htri : AffineIndependent ℝ ![a, b, c]) (hd : d ∈ convexHull ℝ {a, b, c}) (he : e ∈ convexHull ℝ {a, b, c}) (hnoncol : ∀ s ⊆ ({a, b, c, d, e} : Set (ℝ × ℝ)), s.ncard = 3 → ¬Collinear ℝ s) : ∃ T ⊆ ({a, b, c, d, e} : Set (ℝ × ℝ)), T.ncard = 4 ∧ ¬∃ t ∈ T, t ∈ convexHull ℝ (T \ {t}) := by
  sorry
