import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_264_pow_30_sub_pow_twenty (n : ℤ) : (264 : ℤ) ∣ n ^ 30 - n ^ 20 := by
  have h : ∀ m : ZMod 264, m ^ 30 - m ^ 20 = 0 := by decide
  have hz : ((n ^ 30 - n ^ 20 : ℤ) : ZMod 264) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 30 - n ^ 20) 264).mp hz
  exact_mod_cast hdvd
