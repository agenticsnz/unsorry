import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_240_pow_33_sub_pow_29 (n : ℤ) : (240 : ℤ) ∣ n ^ 33 - n ^ 29 := by
  have h : ∀ m : ZMod 240, m ^ 33 - m ^ 29 = 0 := by decide
  have hz : ((n ^ 33 - n ^ 29 : ℤ) : ZMod 240) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 33 - n ^ 29) 240).mp hz
  exact_mod_cast hdvd
