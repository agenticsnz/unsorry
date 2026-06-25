import Mathlib

theorem brualdi_ch8_9 (h : ℕ → ℤ) (k n : ℕ): (fwdDiff 1)^[k] h n = ∑ j ∈ Finset.range (k + 1),
    (-1 : ℤ) ^ (k - j) * Nat.choose k j * h (n + j) := by
  sorry
