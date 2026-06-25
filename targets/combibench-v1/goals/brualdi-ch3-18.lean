import Mathlib

theorem brualdi_ch3_18 (points : Fin 5 → (EuclideanSpace ℝ (Fin 2)))
    (h_points : ∀ i, 0 ≤ ((points i) 0) ∧ ((points i) 0) ≤ 2 ∧ 0 ≤ ((points i) 1) ∧ ((points i) 1) ≤ 2) :
    ∃ i j, i ≠ j ∧ dist (points i) (points j) ≤ √2 := by
  sorry
