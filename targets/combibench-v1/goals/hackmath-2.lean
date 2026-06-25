import Mathlib

theorem hackmath_2 (sols : Finset (Fin 8 → Fin 4))
    (h_sols : ∀ f, f ∈ sols ↔
      ((List.ofFn f).count 0 = 1) ∧ ((List.ofFn f).count 1 = 1) ∧ ((List.ofFn f).count 2 = 1)) :
    sols.card = ((336) : ℕ ) := by
  sorry
