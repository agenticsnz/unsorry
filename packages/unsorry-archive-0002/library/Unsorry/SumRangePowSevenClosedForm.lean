/-
Closed form for the sum of seventh powers over an initial range of naturals:

`24 * ∑_{i=0}^{n} i ^ 7 = n ^ 2 (n + 1) ^ 2 (3 n ^ 4 + 6 n ^ 3 - n ^ 2 - 4 n + 2)`.

The bracket on the right uses truncated subtraction on `ℕ`, so the argument
first establishes a purely additive companion identity by induction and then
transfers it back once the validity of that subtraction is checked.
-/
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Tactic.Ring
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith

theorem sum_range_pow_seven_closed_form (n : ℕ) :
    24 * ∑ i ∈ Finset.range (n + 1), i ^ 7 =
      n ^ 2 * (n + 1) ^ 2 * (3 * n ^ 4 + 6 * n ^ 3 - n ^ 2 - 4 * n + 2) := by
  have key : ∀ m : ℕ,
      24 * ∑ i ∈ Finset.range (m + 1), i ^ 7 + m ^ 2 * (m + 1) ^ 2 * (m ^ 2 + 4 * m) =
        m ^ 2 * (m + 1) ^ 2 * (3 * m ^ 4 + 6 * m ^ 3 + 2) := by
    intro m
    induction m with
    | zero => simp
    | succ k ih =>
      rw [Finset.sum_range_succ, Nat.mul_add]
      set S := ∑ i ∈ Finset.range (k + 1), i ^ 7
      refine Nat.add_right_cancel (m := k ^ 2 * (k + 1) ^ 2 * (k ^ 2 + 4 * k)) ?_
      calc _ = (24 * S + k ^ 2 * (k + 1) ^ 2 * (k ^ 2 + 4 * k))
                + (24 * (k + 1) ^ 7
                  + (k + 1) ^ 2 * (k + 1 + 1) ^ 2 * ((k + 1) ^ 2 + 4 * (k + 1))) := by ring
        _ = k ^ 2 * (k + 1) ^ 2 * (3 * k ^ 4 + 6 * k ^ 3 + 2)
                + (24 * (k + 1) ^ 7
                  + (k + 1) ^ 2 * (k + 1 + 1) ^ 2 * ((k + 1) ^ 2 + 4 * (k + 1))) := by rw [ih]
        _ = _ := by ring
  have hle : n ^ 2 + 4 * n ≤ 3 * n ^ 4 + 6 * n ^ 3 := by
    rcases n with _ | k
    · norm_num
    · nlinarith [Nat.zero_le k, sq_nonneg k]
  have hB : 3 * n ^ 4 + 6 * n ^ 3 - n ^ 2 - 4 * n + 2 + (n ^ 2 + 4 * n) =
      3 * n ^ 4 + 6 * n ^ 3 + 2 := by
    rw [Nat.sub_sub]; omega
  have hmul : n ^ 2 * (n + 1) ^ 2 * (3 * n ^ 4 + 6 * n ^ 3 - n ^ 2 - 4 * n + 2)
        + n ^ 2 * (n + 1) ^ 2 * (n ^ 2 + 4 * n)
      = n ^ 2 * (n + 1) ^ 2 * (3 * n ^ 4 + 6 * n ^ 3 + 2) := by
    rw [← Nat.mul_add, hB]
  exact Nat.add_right_cancel ((key n).trans hmul.symm)
