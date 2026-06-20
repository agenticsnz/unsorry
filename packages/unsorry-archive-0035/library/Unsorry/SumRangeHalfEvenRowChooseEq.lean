import Mathlib

open Finset in
theorem sum_range_half_even_row_choose_eq (n : ℕ) : 2 * ∑ k ∈ Finset.range (n + 1), (2 * n).choose k = 4 ^ n + (2 * n).choose n := by
  have hrefl : (∑ i ∈ range (n + 1), (2 * n).choose (2 * n - i)) =
      ∑ i ∈ Finset.Ico n (2 * n + 1), (2 * n).choose i := by
    have := sum_Ico_reflect (fun j => (2 * n).choose j) 0 (m := n + 1) (n := 2 * n) (by omega)
    simp only [Nat.sub_zero] at this
    rw [show 2 * n + 1 - (n + 1) = n by omega] at this
    simpa using this
  have hsym : (∑ i ∈ range (n + 1), (2 * n).choose (2 * n - i)) =
      ∑ i ∈ range (n + 1), (2 * n).choose i :=
    Finset.sum_congr rfl fun i hi => Nat.choose_symm (by have := Finset.mem_range.1 hi; omega)
  -- ∑ Ico 0 (n+1) = ∑ Ico 0 n + choose n
  have htop : (∑ i ∈ range (n + 1), (2 * n).choose i) =
      (∑ i ∈ Finset.Ico 0 n, (2 * n).choose i) + (2 * n).choose n := by
    rw [Finset.range_eq_Ico, Finset.sum_Ico_succ_top (Nat.zero_le n)]
  -- ∑ Ico 0 n + ∑ Ico n (2n+1) = ∑ Ico 0 (2n+1) = 4^n
  have hcons : (∑ i ∈ Finset.Ico 0 n, (2 * n).choose i) +
      (∑ i ∈ Finset.Ico n (2 * n + 1), (2 * n).choose i) =
      4 ^ n := by
    rw [Finset.sum_Ico_consecutive (fun j => (2 * n).choose j) (Nat.zero_le n) (by omega)]
    rw [← Finset.range_eq_Ico, Nat.sum_range_choose (2 * n)]
    rw [pow_mul]; norm_num
  calc 2 * ∑ k ∈ range (n + 1), (2 * n).choose k
      = (∑ i ∈ range (n + 1), (2 * n).choose i) +
          ∑ i ∈ range (n + 1), (2 * n).choose (2 * n - i) := by rw [hsym, two_mul]
    _ = (∑ i ∈ range (n + 1), (2 * n).choose i) +
          ∑ i ∈ Finset.Ico n (2 * n + 1), (2 * n).choose i := by rw [hrefl]
    _ = 4 ^ n + (2 * n).choose n := by rw [htop]; omega