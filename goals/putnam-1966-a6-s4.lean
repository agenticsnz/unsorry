import Mathlib

theorem putnam_1966_a6_lower (a : ℕ → (ℕ → ℝ)) (ha : ∀ n ≥ 1, a n n = n ∧ ∀ m ≥ 1, m < n → a n m = m * Real.sqrt (1 + a n (m + 1))) (n m : ℕ) (hn : 1 ≤ n) (hm : 1 ≤ m) (hmn : m ≤ n) : (m : ℝ) * (m + 2) - (m : ℝ) * (m + 1) * (m + 2) / (n + 2) ≤ a n m := by
  sorry
