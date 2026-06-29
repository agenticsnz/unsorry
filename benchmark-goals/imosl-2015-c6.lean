import Mathlib

def clean (S : Set ℕ+) (n : ℕ) : Prop :=
  ∃! (S' : Finset ℕ+),
    ((S' : Set _) ⊆ S) ∧ (Odd S'.card) ∧ (∑ s ∈ S', (s : ℕ) = n)

theorem imosl_2015_c6 (S : Set ℕ+) (hS : S.Nonempty): ∀ (N : ℕ), ∃ (m : ℕ), N < m ∧ ¬ clean S m := by
  sorry
