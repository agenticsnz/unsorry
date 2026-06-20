import Mathlib

theorem quartic_n4_plus_four_not_prime (n : ℕ) (hn : 2 ≤ n) : ¬ Nat.Prime (n^4 + 4) := by
  have hfac : n^4 + 4 = (n^2 + 2*n + 2) * (n^2 - 2*n + 2) := by
    have h2n : 2 * n ≤ n^2 + 2 := by nlinarith [sq_nonneg (n - 2), hn]
    have hnn : 2 * n ≤ n^2 := by nlinarith
    zify [hnn, h2n]
    ring
  rw [hfac]
  apply Nat.not_prime_mul (a := n^2 + 2*n + 2) (b := n^2 - 2*n + 2)
  · nlinarith
  · have hnn : 2 * n ≤ n^2 := by nlinarith
    omega