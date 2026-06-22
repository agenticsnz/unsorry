import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_264_pow_seventeen_sub_pow_seven (n : ℤ) : (264 : ℤ) ∣ n ^ 17 - n ^ 7 := by
  have h : ∀ m : ZMod 264, m ^ 17 - m ^ 7 = 0 := by decide
  have hz : ((n ^ 17 - n ^ 7 : ℤ) : ZMod 264) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 17 - n ^ 7) 264).mp hz
  exact_mod_cast hdvd
