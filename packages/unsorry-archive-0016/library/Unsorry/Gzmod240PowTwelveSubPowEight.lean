import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_240_pow_twelve_sub_pow_eight (n : ℤ) : (240 : ℤ) ∣ n ^ 12 - n ^ 8 := by
  have h : ∀ m : ZMod 240, m ^ 12 - m ^ 8 = 0 := by decide
  have hz : ((n ^ 12 - n ^ 8 : ℤ) : ZMod 240) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 12 - n ^ 8) 240).mp hz
  exact_mod_cast hdvd
