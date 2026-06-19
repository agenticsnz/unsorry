import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_264_pow_nineteen_sub_pow_nine (n : ℤ) : (264 : ℤ) ∣ n ^ 19 - n ^ 9 := by
  have h : ∀ m : ZMod 264, m ^ 19 - m ^ 9 = 0 := by decide
  have hz : ((n ^ 19 - n ^ 9 : ℤ) : ZMod 264) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 19 - n ^ 9) 264).mp hz
  exact_mod_cast hdvd
