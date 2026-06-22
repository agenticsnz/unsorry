import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_264_pow_44_sub_pow_34 (n : ℤ) : (264 : ℤ) ∣ n ^ 44 - n ^ 34 := by
  have h : ∀ m : ZMod 264, m ^ 44 - m ^ 34 = 0 := by decide
  have hz : ((n ^ 44 - n ^ 34 : ℤ) : ZMod 264) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 44 - n ^ 34) 264).mp hz
  exact_mod_cast hdvd
