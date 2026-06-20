import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_264_pow_twenty_sub_pow_ten (n : ℤ) : (264 : ℤ) ∣ n ^ 20 - n ^ 10 := by
  have h : ∀ m : ZMod 264, m ^ 20 - m ^ 10 = 0 := by decide
  have hz : ((n ^ 20 - n ^ 10 : ℤ) : ZMod 264) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 20 - n ^ 10) 264).mp hz
  exact_mod_cast hdvd
