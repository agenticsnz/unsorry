import Mathlib

open scoped Finset
def answer : Set ℕ := sorry

theorem imo2020p5 :
    {n : ℕ | 1 < n ∧ ∀ (deck : Fin n → ℕ), (∀ i, 0 < deck i) → (Pairwise fun j k ↦
      ∃ S : Finset (Fin n), S.Nonempty ∧
        (deck j + deck k : ℝ) / 2 = (∏ i ∈ S, (deck i : ℝ)) ^ (1 / (#S : ℝ))) →
      ∀ i j, deck i = deck j} = answer := by
  sorry
