import Mathlib

theorem sum_square_pyramidal_eq_hyper (n : ℕ) : 12 * ∑ k ∈ Finset.range (n + 1), k * (k + 1) * (2 * k + 1) / 6 = n * (n + 1) ^ 2 * (n + 2) := by
  have hdvd : ∀ k : ℕ, 6 ∣ k * (k + 1) * (2 * k + 1) := by
    intro k
    have h : (k * (k + 1) * (2 * k + 1)) % 6 = ((k % 6) * ((k % 6) + 1) * (2 * (k % 6) + 1)) % 6 := by
      conv_lhs => rw [Nat.mul_mod, Nat.mul_mod k, Nat.add_mod (2*k), Nat.mul_mod 2 k]
      conv_rhs => rw [Nat.mul_mod, Nat.mul_mod (k%6), Nat.add_mod (2*(k%6)), Nat.mul_mod 2 (k%6)]
      simp
    rw [Nat.dvd_iff_mod_eq_zero, h]
    have : k % 6 < 6 := Nat.mod_lt _ (by norm_num)
    interval_cases (k % 6) <;> rfl
  have hclosed : ∀ m : ℕ, 2 * ∑ k ∈ Finset.range (m + 1), k * (k + 1) * (2 * k + 1) = m * (m + 1) ^ 2 * (m + 2) := by
    intro m
    induction m with
    | zero => simp
    | succ p ih =>
      rw [Finset.sum_range_succ, Nat.mul_add, ih]
      ring
  have hsum : 6 * ∑ k ∈ Finset.range (n + 1), k * (k + 1) * (2 * k + 1) / 6
            = ∑ k ∈ Finset.range (n + 1), k * (k + 1) * (2 * k + 1) := by
    rw [Finset.mul_sum]
    apply Finset.sum_congr rfl
    intro k _
    rw [Nat.mul_div_cancel' (hdvd k)]
  calc 12 * ∑ k ∈ Finset.range (n + 1), k * (k + 1) * (2 * k + 1) / 6
      = 2 * (6 * ∑ k ∈ Finset.range (n + 1), k * (k + 1) * (2 * k + 1) / 6) := by ring
    _ = 2 * ∑ k ∈ Finset.range (n + 1), k * (k + 1) * (2 * k + 1) := by rw [hsum]
    _ = n * (n + 1) ^ 2 * (n + 2) := hclosed n