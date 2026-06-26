import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_504_pow_22_sub_pow_sixteen (n : ℤ) : (504 : ℤ) ∣ n ^ 22 - n ^ 16 := by
  have h : ∀ m : ZMod 504, m ^ 22 - m ^ 16 = 0 := by decide
  have hz : ((n ^ 22 - n ^ 16 : ℤ) : ZMod 504) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 22 - n ^ 16) 504).mp hz
  exact_mod_cast hdvd
