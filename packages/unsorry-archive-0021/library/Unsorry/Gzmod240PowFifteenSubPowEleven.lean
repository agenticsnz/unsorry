import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_240_pow_fifteen_sub_pow_eleven (n : ℤ) : (240 : ℤ) ∣ n ^ 15 - n ^ 11 := by
  have h : ∀ m : ZMod 240, m ^ 15 - m ^ 11 = 0 := by decide
  have hz : ((n ^ 15 - n ^ 11 : ℤ) : ZMod 240) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 15 - n ^ 11) 240).mp hz
  exact_mod_cast hdvd
