import Mathlib

theorem convex_position_subset (A B : Set (ℝ × ℝ)) (hAB : A ⊆ B) (hB : ¬∃ t ∈ B, t ∈ convexHull ℝ (B \ {t})) : ¬∃ t ∈ A, t ∈ convexHull ℝ (A \ {t}) := by
  sorry
