import Mathlib.Data.Nat.Choose.Basic
import Mathlib.Data.Nat.Choose.Sum
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

theorem sum_range_sq_mul_choose (n : ℕ) :
    4 * (∑ k ∈ Finset.range (n + 1), k ^ 2 * n.choose k) = n * (n + 1) * 2 ^ n := by
  cases n with
  | zero => norm_num
  | succ m =>
    have hterm : ∀ i ∈ Finset.range (m + 1),
        (i + 1) ^ 2 * (m + 1).choose (i + 1)
          = (m + 1) * (i * m.choose i + m.choose i) := by
      intro i _
      have habs : (m + 1) * m.choose i = (m + 1).choose (i + 1) * (i + 1) :=
        Nat.add_one_mul_choose_eq m i
      calc (i + 1) ^ 2 * (m + 1).choose (i + 1)
          = (m + 1).choose (i + 1) * (i + 1) * (i + 1) := by ring
        _ = (m + 1) * m.choose i * (i + 1) := by rw [habs]
        _ = (m + 1) * (i * m.choose i + m.choose i) := by ring
    have h1 : ∑ k ∈ Finset.range (m + 1 + 1), k ^ 2 * (m + 1).choose k
        = (∑ i ∈ Finset.range (m + 1), (i + 1) ^ 2 * (m + 1).choose (i + 1))
          + 0 ^ 2 * (m + 1).choose 0 :=
      Finset.sum_range_succ' (fun k => k ^ 2 * (m + 1).choose k) (m + 1)
    have h2 : (∑ i ∈ Finset.range (m + 1), (i + 1) ^ 2 * (m + 1).choose (i + 1))
        = ∑ i ∈ Finset.range (m + 1), (m + 1) * (i * m.choose i + m.choose i) :=
      Finset.sum_congr rfl hterm
    have h3 : (∑ i ∈ Finset.range (m + 1), (m + 1) * (i * m.choose i + m.choose i))
        = (m + 1) * ∑ i ∈ Finset.range (m + 1), (i * m.choose i + m.choose i) :=
      (Finset.mul_sum _ _ _).symm
    have h4 : (∑ i ∈ Finset.range (m + 1), (i * m.choose i + m.choose i))
        = (∑ i ∈ Finset.range (m + 1), i * m.choose i)
          + ∑ i ∈ Finset.range (m + 1), m.choose i :=
      Finset.sum_add_distrib
    rw [h1, h2, h3, h4, Nat.sum_range_mul_choose, Nat.sum_range_choose]
    cases m with
    | zero => norm_num
    | succ j =>
      have hj : j + 1 - 1 = j := by omega
      rw [hj]
      ring
