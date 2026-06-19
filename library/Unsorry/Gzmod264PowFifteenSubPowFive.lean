import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_264_pow_fifteen_sub_pow_five (n : ℤ) : (264 : ℤ) ∣ n ^ 15 - n ^ 5 := by
  have h : ∀ m : ZMod 264, m ^ 15 - m ^ 5 = 0 := by decide
  have hz : ((n ^ 15 - n ^ 5 : ℤ) : ZMod 264) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 15 - n ^ 5) 264).mp hz
  exact_mod_cast hdvd
