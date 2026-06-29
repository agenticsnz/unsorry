import Mathlib

theorem hackmath_9 (sols : Finset (Fin 6 → ℕ))
    (h_sols : ∀ f, f ∈ sols ↔ ((∀ i, f i > 0) ∧ (∑ i, f i = 10))) :
    sols.card = ((126) : ℕ ) := by
  sorry
