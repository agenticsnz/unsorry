import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_264_pow_31_sub_pow_21 (n : ℤ) : (264 : ℤ) ∣ n ^ 31 - n ^ 21 := by
  have h : ∀ m : ZMod 264, m ^ 31 - m ^ 21 = 0 := by decide
  have hz : ((n ^ 31 - n ^ 21 : ℤ) : ZMod 264) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 31 - n ^ 21) 264).mp hz
  exact_mod_cast hdvd
