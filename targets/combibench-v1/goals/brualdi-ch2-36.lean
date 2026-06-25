import Mathlib

theorem brualdi_ch2_36 {k : ℕ} (n : Fin k → ℕ)
    (sols : Finset (Fin k → ℕ))
    (h_sols : ∀ f, f ∈ sols ↔ (∀ i, f i ≤ n i)) :
    sols.card = ((fun n => (∏ i : Fin k, (n i + 1))) : (Fin k → ℕ) → ℕ ) n := by
  sorry
