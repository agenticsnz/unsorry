import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_504_pow_twenty_sub_pow_fourteen (n : ℤ) : (504 : ℤ) ∣ n ^ 20 - n ^ 14 := by
  have h : ∀ m : ZMod 504, m ^ 20 - m ^ 14 = 0 := by decide
  have hz : ((n ^ 20 - n ^ 14 : ℤ) : ZMod 504) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 20 - n ^ 14) 504).mp hz
  exact_mod_cast hdvd
