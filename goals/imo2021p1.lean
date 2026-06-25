import Mathlib

theorem imo2021p1 {n : ℕ} (hn : 100 ≤ n) {S : Finset ℕ} (hS : S ⊆ Finset.Icc n (2 * n)) :
    (∃ a ∈ S, ∃ b ∈ S, a ≠ b ∧ IsSquare (a + b)) ∨
    (∃ a ∈ Finset.Icc n (2 * n) \ S, ∃ b ∈ Finset.Icc n (2 * n) \ S,
      a ≠ b ∧ IsSquare (a + b)) := by
  sorry
