import Mathlib

theorem putnam_1966_a6_upper (a : ℕ → (ℕ → ℝ)) (ha : ∀ n ≥ 1, a n n = n ∧ ∀ m ≥ 1, m < n → a n m = m * Real.sqrt (1 + a n (m + 1))) (n m : ℕ) (hn : 1 ≤ n) (hm : 1 ≤ m) (hmn : m ≤ n) : a n m ≤ (m : ℝ) * (m + 2) := by
  sorry
