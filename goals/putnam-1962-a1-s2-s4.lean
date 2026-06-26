import Mathlib

theorem interior_not_mem_hull_sameSide (a b d e : ℝ × ℝ) (hde : d ≠ e) (hsep : (affineSpan ℝ ({d, e} : Set (ℝ × ℝ))).SSameSide a b) : d ∉ convexHull ℝ ({a, b, e} : Set (ℝ × ℝ)) := by
  sorry
