import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_264_pow_21_sub_pow_eleven (n : ℤ) : (264 : ℤ) ∣ n ^ 21 - n ^ 11 := by
  have h : ∀ m : ZMod 264, m ^ 21 - m ^ 11 = 0 := by decide
  have hz : ((n ^ 21 - n ^ 11 : ℤ) : ZMod 264) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 21 - n ^ 11) 264).mp hz
  exact_mod_cast hdvd
