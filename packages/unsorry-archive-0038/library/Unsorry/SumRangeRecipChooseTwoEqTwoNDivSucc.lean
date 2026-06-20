import Mathlib

theorem sum_range_recip_choose_two_eq_two_n_div_succ (n : ℕ) : ∑ k ∈ Finset.range n, (1 / ((k + 2).choose 2 : ℚ)) = 2 * n / (n + 1) := by
  induction n with
  | zero => simp
  | succ m ih =>
    rw [Finset.sum_range_succ, ih]
    have hch : ((m + 2).choose 2 : ℚ) = (m + 2) * (m + 1) / 2 := by
      have : (m + 2).choose 2 = (m + 2) * (m + 1) / 2 := by
        rw [Nat.choose_two_right]
        simp
      rw [this, Nat.cast_div]
      · push_cast; ring
      · rw [mul_comm]; exact (Nat.even_mul_succ_self (m + 1)).two_dvd
      · norm_num
    rw [hch]
    have h1 : ((m : ℚ) + 1) ≠ 0 := by positivity
    have h2 : ((m : ℚ) + 2) ≠ 0 := by positivity
    push_cast
    field_simp
    ring