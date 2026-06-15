import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Tactic.Ring
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.NormNum
import Unsorry.SumRangePowFiveClosedForm

/-- Faulhaber-style identity expressing three times the sum of fifth powers over
`Finset.range (n + 1)` through the triangular number `T = ∑ i`. -/
theorem sum_range_pow_five_faulhaber_triangular (n : ℕ) :
    3 * ∑ i ∈ Finset.range (n + 1), i ^ 5
      = (∑ i ∈ Finset.range (n + 1), i) ^ 2
        * (4 * (∑ i ∈ Finset.range (n + 1), i) - 1) := by
  -- The proved closed form for the fifth-power sum.
  have hdep := sum_range_pow_five_closed_form n
  -- Twice the triangular number equals `(n + 1) * n` (Gauss's summation).
  have hgauss : 2 * (∑ i ∈ Finset.range (n + 1), i) = (n + 1) * n := by
    have h := Finset.sum_range_id_mul_two (n + 1)
    rw [Nat.add_sub_cancel] at h
    linarith [h]
  set S := ∑ i ∈ Finset.range (n + 1), i with hSdef
  set P := ∑ i ∈ Finset.range (n + 1), i ^ 5 with hPdef
  -- Rewrite the data attached to `S` in terms of `n`.
  have h4S : 4 * S = 2 * n ^ 2 + 2 * n := by
    have e : 4 * S = 2 * (2 * S) := by ring
    rw [e, hgauss]; ring
  have h4S2 : 4 * S ^ 2 = n ^ 2 * (n + 1) ^ 2 := by
    have e : 4 * S ^ 2 = (2 * S) ^ 2 := by ring
    rw [e, hgauss]; ring
  have hsub : 4 * S - 1 = 2 * n ^ 2 + 2 * n - 1 := by rw [h4S]
  -- Multiply the goal through by `4` and cancel.
  have hcancel : 4 * (3 * P) = 4 * (S ^ 2 * (4 * S - 1)) := by
    calc 4 * (3 * P)
        = 12 * P := by ring
      _ = n ^ 2 * (n + 1) ^ 2 * (2 * n ^ 2 + 2 * n - 1) := hdep
      _ = (4 * S ^ 2) * (2 * n ^ 2 + 2 * n - 1) := by rw [← h4S2]
      _ = (4 * S ^ 2) * (4 * S - 1) := by rw [← hsub]
      _ = 4 * (S ^ 2 * (4 * S - 1)) := by ring
  exact Nat.eq_of_mul_eq_mul_left (by norm_num) hcancel
