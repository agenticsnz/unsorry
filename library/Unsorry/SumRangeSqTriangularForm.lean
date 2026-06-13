import Unsorry.SumRangeSqClosedForm
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Tactic.Ring

theorem sum_range_sq_triangular_form (n : ℕ) :
    3 * ∑ i ∈ Finset.range (n + 1), i ^ 2
      = (∑ i ∈ Finset.range (n + 1), i) * (2 * n + 1) := by
  have h2 : 6 * ∑ i ∈ Finset.range (n + 1), i ^ 2 = n * (n + 1) * (2 * n + 1) :=
    sum_range_sq_closed_form n
  have h1 : (∑ i ∈ Finset.range (n + 1), i) * 2 = (n + 1) * n := by
    rw [Finset.sum_range_id_mul_two, Nat.add_sub_cancel]
  have lhs2 : 2 * (3 * ∑ i ∈ Finset.range (n + 1), i ^ 2) = n * (n + 1) * (2 * n + 1) := by
    rw [← h2]; ring
  have rhs2 : 2 * ((∑ i ∈ Finset.range (n + 1), i) * (2 * n + 1))
      = n * (n + 1) * (2 * n + 1) := by
    have e : 2 * ((∑ i ∈ Finset.range (n + 1), i) * (2 * n + 1))
        = ((∑ i ∈ Finset.range (n + 1), i) * 2) * (2 * n + 1) := by ring
    rw [e, h1]; ring
  exact Nat.eq_of_mul_eq_mul_left (by omega) (lhs2.trans rhs2.symm)
