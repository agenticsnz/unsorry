import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_264_pow_37_sub_pow_27 (n : ℤ) : (264 : ℤ) ∣ n ^ 37 - n ^ 27 := by
  have h : ∀ m : ZMod 264, m ^ 37 - m ^ 27 = 0 := by decide
  have hz : ((n ^ 37 - n ^ 27 : ℤ) : ZMod 264) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 37 - n ^ 27) 264).mp hz
  exact_mod_cast hdvd
