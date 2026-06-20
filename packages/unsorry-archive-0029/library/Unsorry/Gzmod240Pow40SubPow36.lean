import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_240_pow_40_sub_pow_36 (n : ℤ) : (240 : ℤ) ∣ n ^ 40 - n ^ 36 := by
  have h : ∀ m : ZMod 240, m ^ 40 - m ^ 36 = 0 := by decide
  have hz : ((n ^ 40 - n ^ 36 : ℤ) : ZMod 240) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 40 - n ^ 36) 240).mp hz
  exact_mod_cast hdvd
