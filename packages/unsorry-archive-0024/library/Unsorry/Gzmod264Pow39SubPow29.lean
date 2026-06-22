import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_264_pow_39_sub_pow_29 (n : ℤ) : (264 : ℤ) ∣ n ^ 39 - n ^ 29 := by
  have h : ∀ m : ZMod 264, m ^ 39 - m ^ 29 = 0 := by decide
  have hz : ((n ^ 39 - n ^ 29 : ℤ) : ZMod 264) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 39 - n ^ 29) 264).mp hz
  exact_mod_cast hdvd
