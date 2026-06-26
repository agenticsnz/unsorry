import Mathlib

theorem hackmath_1 (sols : Finset (Fin 13 → Fin 2))
    (h_sols : ∀ f, f ∈ sols ↔ ((List.ofFn f).count 0 = 6)) :
    sols.card = ((1716) : ℕ ) := by
  sorry
