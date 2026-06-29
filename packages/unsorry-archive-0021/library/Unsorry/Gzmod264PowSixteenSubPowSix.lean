import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_264_pow_sixteen_sub_pow_six (n : ℤ) : (264 : ℤ) ∣ n ^ 16 - n ^ 6 := by
  have h : ∀ m : ZMod 264, m ^ 16 - m ^ 6 = 0 := by decide
  have hz : ((n ^ 16 - n ^ 6 : ℤ) : ZMod 264) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 16 - n ^ 6) 264).mp hz
  exact_mod_cast hdvd
