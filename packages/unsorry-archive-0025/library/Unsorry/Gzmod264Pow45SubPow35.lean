import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_264_pow_45_sub_pow_35 (n : ℤ) : (264 : ℤ) ∣ n ^ 45 - n ^ 35 := by
  have h : ∀ m : ZMod 264, m ^ 45 - m ^ 35 = 0 := by decide
  have hz : ((n ^ 45 - n ^ 35 : ℤ) : ZMod 264) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 45 - n ^ 35) 264).mp hz
  exact_mod_cast hdvd
