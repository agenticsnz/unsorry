import Mathlib

theorem hackmath_8 (sols : Finset ((Fin 13 → Fin 2) × (Fin 7 → Fin 2)))
    (h_sols : ∀ f, f ∈ sols ↔ (∀ i, f.2 i = 0) ∧ ∀ k, ((List.ofFn f.1).count k  + (List.ofFn f.2).count k = 10)) :
    sols.card = ((286) : ℕ ) := by
  sorry
