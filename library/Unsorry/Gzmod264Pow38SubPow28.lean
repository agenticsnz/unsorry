import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_264_pow_38_sub_pow_28 (n : ℤ) : (264 : ℤ) ∣ n ^ 38 - n ^ 28 := by
  have h : ∀ m : ZMod 264, m ^ 38 - m ^ 28 = 0 := by decide
  have hz : ((n ^ 38 - n ^ 28 : ℤ) : ZMod 264) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 38 - n ^ 28) 264).mp hz
  exact_mod_cast hdvd
