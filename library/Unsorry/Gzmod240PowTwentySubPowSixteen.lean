import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_240_pow_twenty_sub_pow_sixteen (n : ℤ) : (240 : ℤ) ∣ n ^ 20 - n ^ 16 := by
  have h : ∀ m : ZMod 240, m ^ 20 - m ^ 16 = 0 := by decide
  have hz : ((n ^ 20 - n ^ 16 : ℤ) : ZMod 240) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 20 - n ^ 16) 240).mp hz
  exact_mod_cast hdvd
