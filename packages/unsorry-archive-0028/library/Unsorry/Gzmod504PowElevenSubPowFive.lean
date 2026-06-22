import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_504_pow_eleven_sub_pow_five (n : ℤ) : (504 : ℤ) ∣ n ^ 11 - n ^ 5 := by
  have h : ∀ m : ZMod 504, m ^ 11 - m ^ 5 = 0 := by decide
  have hz : ((n ^ 11 - n ^ 5 : ℤ) : ZMod 504) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 11 - n ^ 5) 504).mp hz
  exact_mod_cast hdvd
