import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_240_pow_24_sub_pow_twenty (n : ℤ) : (240 : ℤ) ∣ n ^ 24 - n ^ 20 := by
  have h : ∀ m : ZMod 240, m ^ 24 - m ^ 20 = 0 := by decide
  have hz : ((n ^ 24 - n ^ 20 : ℤ) : ZMod 240) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 24 - n ^ 20) 240).mp hz
  exact_mod_cast hdvd
