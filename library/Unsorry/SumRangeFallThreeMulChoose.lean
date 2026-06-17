import Mathlib
open Nat Finset

theorem sum_range_fall_three_mul_choose (n : ℕ) : 8 * ∑ k ∈ Finset.range (n + 1), k * (k - 1) * (k - 2) * n.choose k = n * (n - 1) * (n - 2) * 2 ^ n := by
  rcases lt_or_ge n 3 with hn | hn
  · interval_cases n <;> simp [Finset.sum_range_succ]
  -- core sum identity
  have core : ∑ k ∈ range (n+1), n.choose k * k.choose 3 = n.choose 3 * 2^(n-3) := by
    obtain ⟨m, rfl⟩ : ∃ m, n = m + 3 := ⟨n - 3, by omega⟩
    rw [show m + 3 + 1 = 3 + (m+1) by ring, Finset.sum_range_add]
    have hz : ∑ x ∈ range 3, (m+3).choose x * x.choose 3 = 0 := by
      simp [Finset.sum_range_succ, Nat.choose]
    rw [hz, zero_add]
    have key : ∀ x ∈ range (m+1), (m+3).choose (3+x) * (3+x).choose 3 = (m+3).choose 3 * m.choose x := by
      intro x hx
      have h3 : (3:ℕ) ≤ 3 + x := by omega
      rw [Nat.choose_mul (n := m+3) (k := 3+x) (s := 3) h3]
      congr 2 <;> omega
    rw [Finset.sum_congr rfl key, ← Finset.mul_sum, Nat.sum_range_choose m, Nat.add_sub_cancel]
  -- rewrite each summand: k*(k-1)*(k-2)*C(n,k) = 6 * (C(n,k)*C(k,3))
  have term : ∀ k ∈ range (n+1), k * (k-1) * (k-2) * n.choose k = 6 * (n.choose k * k.choose 3) := by
    intro k hk
    have hdf : k * (k-1) * (k-2) = 6 * k.choose 3 := by
      have : k.descFactorial 3 = k * (k-1) * (k-2) := by simp [Nat.descFactorial]; ring
      rw [← this, descFactorial_eq_factorial_mul_choose]; norm_num [Nat.factorial]
    rw [hdf]; ring
  rw [Finset.sum_congr rfl term, ← Finset.mul_sum, core]
  have hrhs : n * (n-1) * (n-2) = 6 * n.choose 3 := by
    have : n.descFactorial 3 = n * (n-1) * (n-2) := by simp [Nat.descFactorial]; ring
    rw [← this, descFactorial_eq_factorial_mul_choose]; norm_num [Nat.factorial]
  rw [hrhs]
  have hpow : 2^n = 8 * 2^(n-3) := by
    rw [show (8:ℕ) = 2^3 by norm_num, ← pow_add]; congr 1; omega
  rw [hpow]; ring