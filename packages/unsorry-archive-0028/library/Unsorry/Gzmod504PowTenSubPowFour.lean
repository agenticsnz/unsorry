import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_504_pow_ten_sub_pow_four (n : ℤ) : (504 : ℤ) ∣ n ^ 10 - n ^ 4 := by
  have h : ∀ m : ZMod 504, m ^ 10 - m ^ 4 = 0 := by decide
  have hz : ((n ^ 10 - n ^ 4 : ℤ) : ZMod 504) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 10 - n ^ 4) 504).mp hz
  exact_mod_cast hdvd
