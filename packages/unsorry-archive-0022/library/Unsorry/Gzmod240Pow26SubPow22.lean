import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_240_pow_26_sub_pow_22 (n : ℤ) : (240 : ℤ) ∣ n ^ 26 - n ^ 22 := by
  have h : ∀ m : ZMod 240, m ^ 26 - m ^ 22 = 0 := by decide
  have hz : ((n ^ 26 - n ^ 22 : ℤ) : ZMod 240) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 26 - n ^ 22) 240).mp hz
  exact_mod_cast hdvd
