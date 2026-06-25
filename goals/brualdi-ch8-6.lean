import Mathlib

theorem brualdi_ch8_6 (n : ℕ) (h : ℕ → ℝ) (h' : ∀ i, h i = 2 * i ^ 2 - i + 3) :
    ∑ i ∈ Finset.range (n + 1), h i = ((fun n => ((n + 1) * (4 * n ^ 2 - n + 18) / 6)) : ℕ → ℝ ) n := by
  sorry
