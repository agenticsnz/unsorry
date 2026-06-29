import Mathlib

theorem putnam_1966_b4_labeling (S : Finset ℕ) : ∃ g : ℕ → ℕ, (∀ i ∈ S, 1 ≤ g i) ∧ (∀ i ∈ S, ∀ j ∈ S, j ∣ i → j ≠ i → g j < g i) ∧ (∀ i ∈ S, g i = 1 ∨ ∃ j ∈ S, j ∣ i ∧ j ≠ i ∧ g i = g j + 1) := by
  sorry
