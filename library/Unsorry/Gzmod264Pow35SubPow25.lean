import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_264_pow_35_sub_pow_25 (n : ℤ) : (264 : ℤ) ∣ n ^ 35 - n ^ 25 := by
  have h : ∀ m : ZMod 264, m ^ 35 - m ^ 25 = 0 := by decide
  have hz : ((n ^ 35 - n ^ 25 : ℤ) : ZMod 264) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 35 - n ^ 25) 264).mp hz
  exact_mod_cast hdvd
