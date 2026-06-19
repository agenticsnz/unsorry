import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_264_pow_40_sub_pow_30 (n : ℤ) : (264 : ℤ) ∣ n ^ 40 - n ^ 30 := by
  have h : ∀ m : ZMod 264, m ^ 40 - m ^ 30 = 0 := by decide
  have hz : ((n ^ 40 - n ^ 30 : ℤ) : ZMod 264) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 40 - n ^ 30) 264).mp hz
  exact_mod_cast hdvd
