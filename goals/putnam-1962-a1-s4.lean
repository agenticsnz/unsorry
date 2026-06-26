import Mathlib

theorem mem_convexHull_extremePoints (S : Set (ℝ × ℝ)) (hS : S.ncard = 5) (x : ℝ × ℝ) (hx : x ∈ S) : x ∈ convexHull ℝ {t ∈ S | t ∉ convexHull ℝ (S \ {t})} := by
  sorry
