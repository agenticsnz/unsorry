import Mathlib.Data.Nat.Choose.Basic
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Tactic

open Finset

theorem alt_sum_range_choose_sq_eq_zero_odd (n : ℕ) (hn : Odd n) :
    ∑ k ∈ Finset.range (n + 1), ((-1 : ℤ)) ^ k * (n.choose k : ℤ) ^ 2 = 0 := by
  let f : ℕ → ℤ := fun k => ((-1 : ℤ)) ^ k * (n.choose k : ℤ) ^ 2
  have sq_neg_one_pow (k : ℕ) : ((-1 : ℤ) ^ k) * ((-1 : ℤ) ^ k) = 1 := by
    induction k with
    | zero =>
        norm_num
    | succ k ih =>
        calc
          ((-1 : ℤ) ^ (k + 1)) * ((-1 : ℤ) ^ (k + 1))
              = (((-1 : ℤ) ^ k) * (-1)) * (((-1 : ℤ) ^ k) * (-1)) := by
                  simp [pow_succ]
          _ = ((-1 : ℤ) ^ k) * ((-1 : ℤ) ^ k) := by ring
          _ = 1 := ih
  have reflected_term (k : ℕ) (hk : k ∈ Finset.range (n + 1)) : f (n - k) = -f k := by
    have hkn : k ≤ n := Nat.lt_succ_iff.mp (Finset.mem_range.mp hk)
    have hodd_sub_add : Odd (n - k + k) := by
      simpa [Nat.sub_add_cancel hkn] using hn
    have hprod : ((-1 : ℤ) ^ (n - k)) * ((-1 : ℤ) ^ k) = -1 := by
      rw [← pow_add]
      exact hodd_sub_add.neg_one_pow
    have hsign : ((-1 : ℤ) ^ (n - k)) = -((-1 : ℤ) ^ k) := by
      calc
        ((-1 : ℤ) ^ (n - k))
            = ((-1 : ℤ) ^ (n - k)) * (((-1 : ℤ) ^ k) * ((-1 : ℤ) ^ k)) := by
                rw [sq_neg_one_pow k, mul_one]
        _ = (((-1 : ℤ) ^ (n - k)) * ((-1 : ℤ) ^ k)) * ((-1 : ℤ) ^ k) := by ring
        _ = -((-1 : ℤ) ^ k) := by rw [hprod]; ring
    have hchoose : n.choose (n - k) = n.choose k := by
      simpa [eq_comm] using Nat.choose_symm hkn
    calc
      f (n - k)
          = -((-1 : ℤ) ^ k) * (n.choose k : ℤ) ^ 2 := by
              simp [f, hsign, hchoose]
      _ = -f k := by ring
  have hreflect :
      (∑ k ∈ Finset.range (n + 1), f (n - k)) = ∑ k ∈ Finset.range (n + 1), f k := by
    simpa using (Finset.sum_range_reflect f (n + 1))
  have hneg :
      (∑ k ∈ Finset.range (n + 1), f (n - k)) = -∑ k ∈ Finset.range (n + 1), f k := by
    calc
      (∑ k ∈ Finset.range (n + 1), f (n - k))
          = ∑ k ∈ Finset.range (n + 1), -f k := by
              exact Finset.sum_congr rfl reflected_term
      _ = -∑ k ∈ Finset.range (n + 1), f k := by simp
  have hself :
      (∑ k ∈ Finset.range (n + 1), f k) = -∑ k ∈ Finset.range (n + 1), f k :=
    hreflect.symm.trans hneg
  change (∑ k ∈ Finset.range (n + 1), f k) = 0
  linarith
