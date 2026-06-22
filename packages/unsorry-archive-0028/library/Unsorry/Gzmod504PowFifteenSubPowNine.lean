import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_504_pow_fifteen_sub_pow_nine (n : ℤ) : (504 : ℤ) ∣ n ^ 15 - n ^ 9 := by
  have h : ∀ m : ZMod 504, m ^ 15 - m ^ 9 = 0 := by decide
  have hz : ((n ^ 15 - n ^ 9 : ℤ) : ZMod 504) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 15 - n ^ 9) 504).mp hz
  exact_mod_cast hdvd
