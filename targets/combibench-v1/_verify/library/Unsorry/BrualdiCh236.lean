import Mathlib.Data.Fintype.BigOperators

/-!
# Brualdi, Chapter 2, Exercise 36

The functions `f : Fin k → ℕ` with `f i ≤ n i` for every `i` are exactly the
elements of the pi-finset `∏ i, Finset.range (n i + 1)`. Its cardinality is the
product of the cardinalities of the factors, namely `∏ i, (n i + 1)`.
-/

theorem brualdi_ch2_36 {k : ℕ} (n : Fin k → ℕ)
    (sols : Finset (Fin k → ℕ))
    (h_sols : ∀ f, f ∈ sols ↔ (∀ i, f i ≤ n i)) :
    sols.card = ((fun n => (∏ i : Fin k, (n i + 1))) : (Fin k → ℕ) → ℕ ) n := by
  have h : sols = Fintype.piFinset (fun i => Finset.range (n i + 1)) := by
    ext f
    simp [h_sols, Fintype.mem_piFinset, Nat.lt_succ_iff]
  rw [h, Fintype.card_piFinset]
  simp
