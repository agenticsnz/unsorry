import Mathlib

theorem putnam_1962_b5_term_le_exp (n i : ℤ) (hi : 1 ≤ i) (hin : i ≤ n) :
    ((i : ℝ) / n) ^ (n : ℝ) ≤ Real.exp ((i : ℝ) - n) := by
  have hn : (0 : ℤ) < n := by linarith
  have hnR : (0 : ℝ) < (n : ℝ) := by exact_mod_cast hn
  have hiR : (0 : ℝ) < (i : ℝ) := by exact_mod_cast hi
  have hpos : 0 < (i : ℝ) / (n : ℝ) := div_pos hiR hnR
  rw [Real.rpow_def_of_pos hpos]
  apply Real.exp_le_exp.mpr
  -- log(i/n) ≤ i/n - 1; умножаем на n > 0 и упрощаем: n*log(i/n) ≤ i - n
  have h2 := Real.log_le_sub_one_of_pos hpos
  have h3 := mul_le_mul_of_nonneg_left h2 (le_of_lt hnR)
  have h4 : (n : ℝ) * ((i : ℝ) / (n : ℝ) - 1) = (i : ℝ) - (n : ℝ) := by
    field_simp
  have h5 : (n : ℝ) * Real.log ((i : ℝ) / (n : ℝ)) =
      Real.log ((i : ℝ) / (n : ℝ)) * (n : ℝ) := mul_comm _ _
  linarith
