import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_264_pow_34_sub_pow_24 (n : ℤ) : (264 : ℤ) ∣ n ^ 34 - n ^ 24 := by
  have h : ∀ m : ZMod 264, m ^ 34 - m ^ 24 = 0 := by decide
  have hz : ((n ^ 34 - n ^ 24 : ℤ) : ZMod 264) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 34 - n ^ 24) 264).mp hz
  exact_mod_cast hdvd
