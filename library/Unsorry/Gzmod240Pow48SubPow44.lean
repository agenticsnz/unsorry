import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_240_pow_48_sub_pow_44 (n : ℤ) : (240 : ℤ) ∣ n ^ 48 - n ^ 44 := by
  have h : ∀ m : ZMod 240, m ^ 48 - m ^ 44 = 0 := by decide
  have hz : ((n ^ 48 - n ^ 44 : ℤ) : ZMod 240) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 48 - n ^ 44) 240).mp hz
  exact_mod_cast hdvd
