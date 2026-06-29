import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Log.Basic

/-!
# Putnam 1962 B5 (term bound)

A single term bound used in Putnam 1962 B5: for integers `1 ≤ i ≤ n`,
`(i / n) ^ n ≤ exp (i - n)`.

The proof reduces, via the strictly positive base, to the elementary
estimate `log x ≤ x - 1`.
-/

open Real

theorem putnam_1962_b5_term_le_exp (n i : ℤ) (hi : 1 ≤ i) (hin : i ≤ n) :
    ((i : ℝ) / n) ^ (n : ℝ) ≤ Real.exp ((i : ℝ) - n) := by
  have hn1 : (1 : ℤ) ≤ n := le_trans hi hin
  have hnR : (1 : ℝ) ≤ (n : ℝ) := by exact_mod_cast hn1
  have hnpos : (0 : ℝ) < (n : ℝ) := by linarith
  have hiR : (1 : ℝ) ≤ (i : ℝ) := by exact_mod_cast hi
  have hipos : (0 : ℝ) < (i : ℝ) := by linarith
  have hratio : (0 : ℝ) < (i : ℝ) / n := div_pos hipos hnpos
  rw [Real.rpow_def_of_pos hratio]
  apply Real.exp_le_exp.mpr
  have hlog : Real.log ((i : ℝ) / n) ≤ (i : ℝ) / n - 1 :=
    Real.log_le_sub_one_of_pos hratio
  have hmul : Real.log ((i : ℝ) / n) * n ≤ ((i : ℝ) / n - 1) * n :=
    mul_le_mul_of_nonneg_right hlog (le_of_lt hnpos)
  have hne : (n : ℝ) ≠ 0 := ne_of_gt hnpos
  have heq : ((i : ℝ) / n - 1) * n = (i : ℝ) - n := by
    field_simp
  linarith [hmul, heq.le, heq.ge]
