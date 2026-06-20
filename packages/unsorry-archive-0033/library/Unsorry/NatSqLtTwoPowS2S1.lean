import Mathlib.Tactic.Linarith

/-- For every natural number `n` with `5 ≤ n`, we have `(n + 1) ^ 2 ≤ 2 * n ^ 2`. -/
theorem succ_square_le_two_mul_square_of_five {n : ℕ} (hn : 5 ≤ n) :
    (n + 1) ^ 2 ≤ 2 * n ^ 2 := by
  nlinarith [hn, mul_le_mul_of_nonneg_right hn (Nat.zero_le n)]
