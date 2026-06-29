import Mathlib

theorem putnam_1993_a4 (x : Fin 19 → ℤ)
  (y : Fin 93 → ℤ)
  (hx : ∀ i, 0 < x i ∧ x i ≤ 93)
  (hy : ∀ j, 0 < y j ∧ y j ≤ 19) :
  ∃ (is : Finset (Fin 19)) (js : Finset (Fin 93)),
    is ≠ ∅ ∧ (∑ i : is, x i) = (∑ j : js, y j) := by
  sorry
