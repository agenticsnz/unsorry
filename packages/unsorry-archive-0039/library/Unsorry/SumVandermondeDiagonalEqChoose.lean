import Mathlib

theorem sum_vandermonde_diagonal_eq_choose (n m : ℕ) : ∑ k ∈ Finset.range (n + 1), n.choose k * m.choose k = (n + m).choose n := by
  rw [Nat.add_choose_eq, Finset.Nat.sum_antidiagonal_eq_sum_range_succ_mk]
  rw [← Finset.sum_range_reflect]
  apply Finset.sum_congr rfl
  intro k h
  have hk : k ≤ n := Finset.mem_range_succ_iff.mp h
  have h1 : n + 1 - 1 - k = n - k := by omega
  rw [h1, Nat.choose_symm hk]
