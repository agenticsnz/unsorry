import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_264_pow_24_sub_pow_fourteen (n : ℤ) : (264 : ℤ) ∣ n ^ 24 - n ^ 14 := by
  have h : ∀ m : ZMod 264, m ^ 24 - m ^ 14 = 0 := by decide
  have hz : ((n ^ 24 - n ^ 14 : ℤ) : ZMod 264) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 24 - n ^ 14) 264).mp hz
  exact_mod_cast hdvd
