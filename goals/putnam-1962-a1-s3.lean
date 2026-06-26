import Mathlib

theorem interior_card_le_two (S : Set (ℝ × ℝ)) (hS : S.ncard = 5) (hnoncol : ∀ s ⊆ S, s.ncard = 3 → ¬Collinear ℝ s) : {t ∈ S | t ∈ convexHull ℝ (S \ {t})}.ncard ≤ 2 := by
  sorry
