import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_264_pow_36_sub_pow_26 (n : ℤ) : (264 : ℤ) ∣ n ^ 36 - n ^ 26 := by
  have h : ∀ m : ZMod 264, m ^ 36 - m ^ 26 = 0 := by decide
  have hz : ((n ^ 36 - n ^ 26 : ℤ) : ZMod 264) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 36 - n ^ 26) 264).mp hz
  exact_mod_cast hdvd
