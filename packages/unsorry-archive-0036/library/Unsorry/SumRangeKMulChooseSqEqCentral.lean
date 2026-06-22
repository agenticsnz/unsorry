import Mathlib

open Finset Finset.Nat

theorem sum_range_k_mul_choose_sq_eq_central (n : ℕ) (hn : 1 ≤ n) : ∑ k ∈ Finset.range (n + 1), k * n.choose k ^ 2 = n * (2 * n - 1).choose (n - 1) := by
  obtain ⟨m, rfl⟩ : ∃ m, n = m + 1 := ⟨n - 1, by omega⟩
  have hsub1 : 2 * (m + 1) - 1 = 2 * m + 1 := by omega
  have hsub2 : (m + 1) - 1 = m := by omega
  rw [hsub1, hsub2]
  have step1 : ∑ k ∈ Finset.range (m + 1 + 1), k * (m+1).choose k ^ 2
      = (m+1) * ∑ j ∈ Finset.range (m + 1), (m).choose j * (m+1).choose (j+1) := by
    rw [Finset.sum_range_succ' (fun k => k * (m+1).choose k ^ 2) (m+1), Finset.mul_sum]
    simp only [Nat.zero_mul, add_zero]
    apply Finset.sum_congr rfl
    intro j hj
    have h := Nat.add_one_mul_choose_eq m j
    rw [sq]
    rw [show (m+1) * (m.choose j * (m+1).choose (j+1)) = ((m+1) * m.choose j) * (m+1).choose (j+1) by ring]
    rw [h]
    ring
  have step2 : ∑ j ∈ Finset.range (m + 1), (m).choose j * (m+1).choose (j+1) = (2*m+1).choose m := by
    have hv := Nat.add_choose_eq m (m+1) m
    rw [Nat.sum_antidiagonal_eq_sum_range_succ_mk] at hv
    rw [show 2*m+1 = m + (m+1) by ring, hv]
    apply Finset.sum_congr rfl
    intro j hj
    rw [Finset.mem_range] at hj
    congr 1
    rw [← Nat.choose_symm (by omega : m - j ≤ m + 1)]
    congr 1
    omega
  rw [step1, step2]