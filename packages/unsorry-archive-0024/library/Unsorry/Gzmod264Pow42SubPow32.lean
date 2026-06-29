import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_264_pow_42_sub_pow_32 (n : ℤ) : (264 : ℤ) ∣ n ^ 42 - n ^ 32 := by
  have h : ∀ m : ZMod 264, m ^ 42 - m ^ 32 = 0 := by decide
  have hz : ((n ^ 42 - n ^ 32 : ℤ) : ZMod 264) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 42 - n ^ 32) 264).mp hz
  exact_mod_cast hdvd
