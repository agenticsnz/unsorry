import Mathlib

theorem brualdi_ch5_26 (n k : ℕ) (h1 : 1 ≤ k) (h2 : k ≤ n) :
    ∑ k ∈ Finset.Icc 1 n, Nat.choose n k * Nat.choose n (k - 1) =
    (1 / 2 : ℚ) * Nat.choose (2 * n + 1) (n + 1) - Nat.choose (2 * n) n := by
  sorry
