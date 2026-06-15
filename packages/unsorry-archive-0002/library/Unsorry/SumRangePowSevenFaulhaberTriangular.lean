import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Tactic.Ring
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.NormNum
import Unsorry.SumRangePowSevenClosedForm

theorem sum_range_pow_seven_faulhaber_triangular (n : ℕ) :
    3 * ∑ i ∈ Finset.range (n + 1), i ^ 7
      = (∑ i ∈ Finset.range (n + 1), i) ^ 2
        * (6 * (∑ i ∈ Finset.range (n + 1), i) ^ 2 - 4 * (∑ i ∈ Finset.range (n + 1), i) + 1) := by
  have hdep := sum_range_pow_seven_closed_form n
  have hgauss : 2 * (∑ i ∈ Finset.range (n + 1), i) = (n + 1) * n := by
    have h := Finset.sum_range_id_mul_two (n + 1)
    rw [Nat.add_sub_cancel] at h
    linarith [h]
  have hle : ∀ m : ℕ, 4 * m ≤ 6 * m ^ 2 := by
    intro m
    rcases m with _ | k
    · simp
    · nlinarith [Nat.zero_le k, Nat.zero_le (k ^ 2)]
  have hCle : ∀ m : ℕ, m ^ 2 + 4 * m ≤ 3 * m ^ 4 + 6 * m ^ 3 := by
    intro m
    rcases m with _ | k
    · simp
    · nlinarith [Nat.zero_le k, Nat.zero_le (k ^ 2), Nat.zero_le (k ^ 3), Nat.zero_le (k ^ 4)]
  set S := ∑ i ∈ Finset.range (n + 1), i with hSdef
  set P := ∑ i ∈ Finset.range (n + 1), i ^ 7 with hPdef
  set B := 6 * S ^ 2 - 4 * S + 1 with hBdef
  have e1 : 12 * S ^ 2 = 3 * n ^ 4 + 6 * n ^ 3 + 3 * n ^ 2 := by
    have e : 12 * S ^ 2 = 3 * (2 * S) ^ 2 := by ring
    rw [e, hgauss]; ring
  have e2 : 8 * S = 4 * n ^ 2 + 4 * n := by
    have e : 8 * S = 4 * (2 * S) := by ring
    rw [e, hgauss]; ring
  have h4S2 : 4 * S ^ 2 = n ^ 2 * (n + 1) ^ 2 := by
    have e : 4 * S ^ 2 = (2 * S) ^ 2 := by ring
    rw [e, hgauss]; ring
  have hleS : 4 * S ≤ 6 * S ^ 2 := hle S
  have hClen : n ^ 2 + 4 * n ≤ 3 * n ^ 4 + 6 * n ^ 3 := hCle n
  have hCB : 3 * n ^ 4 + 6 * n ^ 3 - n ^ 2 - 4 * n + 2 = 2 * B := by
    rw [hBdef]; omega
  have hcancel : 8 * (3 * P) = 8 * (S ^ 2 * B) := by
    calc 8 * (3 * P)
        = 24 * P := by ring
      _ = n ^ 2 * (n + 1) ^ 2 * (3 * n ^ 4 + 6 * n ^ 3 - n ^ 2 - 4 * n + 2) := hdep
      _ = 4 * S ^ 2 * (3 * n ^ 4 + 6 * n ^ 3 - n ^ 2 - 4 * n + 2) := by rw [← h4S2]
      _ = 4 * S ^ 2 * (2 * B) := by rw [hCB]
      _ = 8 * (S ^ 2 * B) := by ring
  exact Nat.eq_of_mul_eq_mul_left (by norm_num) hcancel
