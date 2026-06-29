import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_240_pow_27_sub_pow_23 (n : ℤ) : (240 : ℤ) ∣ n ^ 27 - n ^ 23 := by
  have h : ∀ m : ZMod 240, m ^ 27 - m ^ 23 = 0 := by decide
  have hz : ((n ^ 27 - n ^ 23 : ℤ) : ZMod 240) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 27 - n ^ 23) 240).mp hz
  exact_mod_cast hdvd
