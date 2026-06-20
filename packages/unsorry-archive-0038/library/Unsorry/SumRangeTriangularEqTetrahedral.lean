import Mathlib

theorem sum_range_triangular_eq_tetrahedral (n : ℕ) : 6 * ∑ k ∈ Finset.range (n + 1), k * (k + 1) / 2 = n * (n + 1) * (n + 2) := by
  induction n with
  | zero => simp
  | succ m ih =>
    rw [Finset.sum_range_succ, Nat.mul_add, ih]
    have hdvd : 2 ∣ (m + 1) * (m + 1 + 1) := (Nat.even_mul_succ_self (m + 1)).two_dvd
    have h : (m + 1) * (m + 1 + 1) / 2 = (m + 1) * (m + 2) / 2 := by ring_nf
    have heq : 2 * ((m + 1) * (m + 1 + 1) / 2) = (m + 1) * (m + 1 + 1) :=
      Nat.two_mul_div_two_of_even (Nat.even_mul_succ_self (m + 1))
    nlinarith [heq]