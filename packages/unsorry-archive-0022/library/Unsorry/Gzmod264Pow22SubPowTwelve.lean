import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_264_pow_22_sub_pow_twelve (n : ℤ) : (264 : ℤ) ∣ n ^ 22 - n ^ 12 := by
  have h : ∀ m : ZMod 264, m ^ 22 - m ^ 12 = 0 := by decide
  have hz : ((n ^ 22 - n ^ 12 : ℤ) : ZMod 264) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 22 - n ^ 12) 264).mp hz
  exact_mod_cast hdvd
