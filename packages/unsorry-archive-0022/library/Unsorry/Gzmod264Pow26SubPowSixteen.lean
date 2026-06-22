import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_264_pow_26_sub_pow_sixteen (n : ℤ) : (264 : ℤ) ∣ n ^ 26 - n ^ 16 := by
  have h : ∀ m : ZMod 264, m ^ 26 - m ^ 16 = 0 := by decide
  have hz : ((n ^ 26 - n ^ 16 : ℤ) : ZMod 264) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 26 - n ^ 16) 264).mp hz
  exact_mod_cast hdvd
