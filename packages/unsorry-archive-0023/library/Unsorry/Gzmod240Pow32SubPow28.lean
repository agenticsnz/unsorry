import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_240_pow_32_sub_pow_28 (n : ℤ) : (240 : ℤ) ∣ n ^ 32 - n ^ 28 := by
  have h : ∀ m : ZMod 240, m ^ 32 - m ^ 28 = 0 := by decide
  have hz : ((n ^ 32 - n ^ 28 : ℤ) : ZMod 240) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 32 - n ^ 28) 240).mp hz
  exact_mod_cast hdvd
