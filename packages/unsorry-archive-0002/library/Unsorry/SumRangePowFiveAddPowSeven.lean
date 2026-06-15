import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

theorem sum_range_pow_five_add_pow_seven (n : ℕ) :
    (∑ i ∈ Finset.range (n + 1), i ^ 5) + (∑ i ∈ Finset.range (n + 1), i ^ 7)
      = 2 * (∑ i ∈ Finset.range (n + 1), i) ^ 4 := by
  -- A clean, subtraction-free combined identity, proved by induction.
  have key : ∀ m : ℕ,
      8 * ((∑ i ∈ Finset.range (m + 1), i ^ 5) + (∑ i ∈ Finset.range (m + 1), i ^ 7))
        = m ^ 4 * (m + 1) ^ 4 := by
    intro m
    induction m with
    | zero => simp
    | succ k ih =>
      rw [Finset.sum_range_succ (fun i => i ^ 5) (k + 1),
        Finset.sum_range_succ (fun i => i ^ 7) (k + 1)]
      generalize ha : (∑ i ∈ Finset.range (k + 1), i ^ 5) = a at *
      generalize hb : (∑ i ∈ Finset.range (k + 1), i ^ 7) = b at *
      have step : 8 * (a + b) + (8 * (k + 1) ^ 5 + 8 * (k + 1) ^ 7)
          = (k + 1) ^ 4 * (k + 1 + 1) ^ 4 := by
        rw [ih]; ring
      rw [← step]; ring
  -- Gauss summation: twice the linear sum is n * (n + 1).
  have gauss : (∑ i ∈ Finset.range (n + 1), i) * 2 = (n + 1) * n := by
    simpa using Finset.sum_range_id_mul_two (n + 1)
  -- Hence sixteen times the fourth power of the linear sum is the same polynomial.
  have h16 : 16 * (∑ i ∈ Finset.range (n + 1), i) ^ 4 = n ^ 4 * (n + 1) ^ 4 := by
    calc 16 * (∑ i ∈ Finset.range (n + 1), i) ^ 4
        = ((∑ i ∈ Finset.range (n + 1), i) * 2) ^ 4 := by ring
      _ = ((n + 1) * n) ^ 4 := by rw [gauss]
      _ = n ^ 4 * (n + 1) ^ 4 := by ring
  -- Combine and cancel the common positive factor.
  have h8 : 8 * ((∑ i ∈ Finset.range (n + 1), i ^ 5) + (∑ i ∈ Finset.range (n + 1), i ^ 7))
      = 8 * (2 * (∑ i ∈ Finset.range (n + 1), i) ^ 4) := by
    rw [key n, ← h16]; ring
  exact Nat.eq_of_mul_eq_mul_left (by norm_num) h8
