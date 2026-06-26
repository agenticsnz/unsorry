import Mathlib

open Nat in
theorem sum_range_stirling_first_row_eq_factorial (n : ℕ) :
    ∑ k ∈ Finset.range (n + 1), Nat.stirlingFirst n k = n.factorial := by
  induction n with
  | zero => simp
  | succ n ih =>
    -- Split the sum over range (n+2): the k=0 term is 0, reindex the rest.
    rw [Finset.sum_range_succ']
    simp only [Nat.stirlingFirst_succ_zero, add_zero]
    -- Now sum is over k ∈ range (n+1) of stirlingFirst (n+1) (k+1)
    -- = ∑ k, (n * stirlingFirst n (k+1) + stirlingFirst n k)
    have hsplit : ∑ k ∈ Finset.range (n + 1), Nat.stirlingFirst (n + 1) (k + 1)
        = n * (∑ k ∈ Finset.range (n + 1), Nat.stirlingFirst n (k + 1))
          + ∑ k ∈ Finset.range (n + 1), Nat.stirlingFirst n k := by
      rw [Finset.mul_sum, ← Finset.sum_add_distrib]
      apply Finset.sum_congr rfl
      intro k _
      rw [Nat.stirlingFirst_succ_succ]
    rw [hsplit]
    -- ∑ k ∈ range (n+1), stirlingFirst n (k+1) = ∑ k ∈ range (n+1), stirlingFirst n k - stirlingFirst n 0
    -- Use sum_range_succ' in reverse on the inner factorial sum.
    have hreidx : ∑ k ∈ Finset.range (n + 1), Nat.stirlingFirst n (k + 1)
        + Nat.stirlingFirst n 0 = ∑ k ∈ Finset.range (n + 1), Nat.stirlingFirst n k := by
      rw [← Finset.sum_range_succ' (fun k => Nat.stirlingFirst n k) (n + 1)]
      rw [Finset.sum_range_succ]
      rw [Nat.stirlingFirst_eq_zero_of_lt (Nat.lt_succ_self n), add_zero]
    rw [ih] at hreidx ⊢
    -- hreidx : (∑ ... (k+1)) + stirlingFirst n 0 = n!
    -- goal   : n * (∑ ... (k+1)) + n! = (n+1)!
    have key : n * (∑ k ∈ Finset.range (n + 1), Nat.stirlingFirst n (k + 1))
        = n * n.factorial := by
      cases n with
      | zero => simp
      | succ m =>
        rw [Nat.stirlingFirst_succ_zero, add_zero] at hreidx
        rw [hreidx]
    rw [key, Nat.factorial_succ]
    ring