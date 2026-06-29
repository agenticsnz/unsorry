import Mathlib

theorem vertex_not_mem_hull_interiors (a b c d e : ℝ × ℝ) (htri : AffineIndependent ℝ ![a, b, c]) (hd : d ∈ convexHull ℝ ({a, b, c} : Set (ℝ × ℝ))) (he : e ∈ convexHull ℝ ({a, b, c} : Set (ℝ × ℝ))) (had : a ≠ d) (hae : a ≠ e) : a ∉ convexHull ℝ ({b, d, e} : Set (ℝ × ℝ)) := by
  sorry
