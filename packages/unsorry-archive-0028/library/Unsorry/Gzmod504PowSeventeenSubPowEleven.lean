import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_504_pow_seventeen_sub_pow_eleven (n : ℤ) : (504 : ℤ) ∣ n ^ 17 - n ^ 11 := by
  have h : ∀ m : ZMod 504, m ^ 17 - m ^ 11 = 0 := by decide
  have hz : ((n ^ 17 - n ^ 11 : ℤ) : ZMod 504) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 17 - n ^ 11) 504).mp hz
  exact_mod_cast hdvd
