import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_240_pow_29_sub_pow_25 (n : ℤ) : (240 : ℤ) ∣ n ^ 29 - n ^ 25 := by
  have h : ∀ m : ZMod 240, m ^ 29 - m ^ 25 = 0 := by decide
  have hz : ((n ^ 29 - n ^ 25 : ℤ) : ZMod 240) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 29 - n ^ 25) 240).mp hz
  exact_mod_cast hdvd
