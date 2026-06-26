import Mathlib

theorem brualdi_ch6_11 (sols : Finset (Equiv.Perm (Finset.Icc 1 8)))
    (h_sols : ∀ σ, σ ∈ sols ↔ (∀ i, Even i.1 → σ i ≠ i)) :
    sols.card = ((24024) : ℕ ) := by
  sorry
