import Mathlib

open Finset in
theorem sum_range_k_sq_mul_choose_eq (n : ℕ) : 4 * ∑ k ∈ Finset.range (n + 1), k ^ 2 * n.choose k = n * (n + 1) * 2 ^ n := by
  rcases n with _ | m
  · simp
  -- n = m + 1
  have key : ∀ k, (k + 1) ^ 2 * (m + 1).choose (k + 1) = (m + 1) * ((k + 1) * m.choose k) := by
    intro k
    have h := Nat.add_one_mul_choose_eq m k  -- (m+1) * C(m,k) = C(m+1,k+1) * (k+1)
    have e : (k + 1) * ((m + 1) * m.choose k) = (k + 1) * ((m + 1).choose (k + 1) * (k + 1)) := by
      rw [h]
    nlinarith [e]
  rw [Finset.sum_range_succ']
  have z : (0 : ℕ) ^ 2 * (m + 1).choose 0 = 0 := by simp
  rw [z, add_zero]
  -- rewrite each summand via key
  have hsum : ∑ k ∈ Finset.range (m + 1), (k + 1) ^ 2 * (m + 1).choose (k + 1)
      = (m + 1) * ∑ k ∈ Finset.range (m + 1), (k + 1) * m.choose k := by
    rw [Finset.mul_sum]
    exact Finset.sum_congr rfl (fun k _ => key k)
  rw [hsum]
  -- split (k+1)*C(m,k) = k*C(m,k) + C(m,k)
  have hsplit : ∑ k ∈ Finset.range (m + 1), (k + 1) * m.choose k
      = (∑ k ∈ Finset.range (m + 1), k * m.choose k) + ∑ k ∈ Finset.range (m + 1), m.choose k := by
    rw [← Finset.sum_add_distrib]
    exact Finset.sum_congr rfl (fun k _ => by ring)
  rw [hsplit, Nat.sum_range_mul_choose, Nat.sum_range_choose]
  -- goal: 4 * ((m+1) * (m * 2^(m-1) + 2^m)) = (m+1) * (m+1+1) * 2^(m+1)
  rcases m with _ | p
  · simp
  -- m = p + 1, so m - 1 = p, 2^m = 2^(p+1) = 2 * 2^p, 2^(m-1)=2^p
  simp only [Nat.add_sub_cancel]
  ring_nf