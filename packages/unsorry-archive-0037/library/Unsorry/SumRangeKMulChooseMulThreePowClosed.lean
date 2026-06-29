import Mathlib

theorem sum_range_k_mul_choose_mul_three_pow_closed (n : ℕ) : 4 * ∑ k ∈ Finset.range (n + 1), k * n.choose k * 3 ^ k = 3 * n * 4 ^ n := by
  rcases n with _ | m
  · simp
  · -- n = m + 1
    rw [Finset.sum_range_succ']
    simp only [Nat.zero_mul, Nat.add_zero, pow_zero, Nat.mul_one]
    have key : ∀ k, (k + 1) * (m + 1).choose (k + 1) * 3 ^ (k + 1)
        = (m + 1) * (m.choose k * 3 ^ k) * 3 := by
      intro k
      have h := Nat.add_one_mul_choose_eq m k
      -- h : (m+1) * choose m k = choose (m+1) (k+1) * (k+1)
      have h2 : (k + 1) * (m + 1).choose (k + 1) = (m + 1) * m.choose k := by
        rw [h]; ring
      rw [pow_succ]
      calc (k + 1) * (m + 1).choose (k + 1) * (3 ^ k * 3)
          = ((k + 1) * (m + 1).choose (k + 1)) * (3 ^ k * 3) := by ring
        _ = ((m + 1) * m.choose k) * (3 ^ k * 3) := by rw [h2]
        _ = (m + 1) * (m.choose k * 3 ^ k) * 3 := by ring
    rw [Finset.sum_congr rfl (fun k _ => key k)]
    have factor : ∀ k, (m + 1) * (m.choose k * 3 ^ k) * 3
        = (m.choose k * 3 ^ k) * ((m + 1) * 3) := by intro k; ring
    rw [Finset.sum_congr rfl (fun k _ => factor k), ← Finset.sum_mul]
    have hsum : ∑ k ∈ Finset.range (m + 1), m.choose k * 3 ^ k = 4 ^ m := by
      have hb := add_pow (3 : ℕ) 1 m
      simp only [one_pow, mul_one] at hb
      norm_num at hb
      rw [hb]
      apply Finset.sum_congr rfl
      intro k _
      ring
    rw [hsum]
    ring