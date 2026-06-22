import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_240_pow_30_sub_pow_26 (n : ℤ) : (240 : ℤ) ∣ n ^ 30 - n ^ 26 := by
  have h : ∀ m : ZMod 240, m ^ 30 - m ^ 26 = 0 := by decide
  have hz : ((n ^ 30 - n ^ 26 : ℤ) : ZMod 240) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 30 - n ^ 26) 240).mp hz
  exact_mod_cast hdvd
