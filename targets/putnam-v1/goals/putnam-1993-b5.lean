import Mathlib

theorem putnam_1993_b5 :
  ¬∃ p : Fin 4 → (EuclideanSpace ℝ (Fin 2)),
    ∀ i j, i ≠ j →
      (∃ n : ℤ, dist (p i) (p j) = n ∧ Odd n) := by
  sorry
