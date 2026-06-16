import Mathlib

theorem candido_sum_quartics_twice_square (a b : ℤ) : ∃ k : ℤ, a ^ 4 + b ^ 4 + (a + b) ^ 4 = 2 * k ^ 2 := by
  exact ⟨a ^ 2 + a * b + b ^ 2, by ring⟩
