import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_240_pow_sixteen_sub_pow_twelve (n : ℤ) : (240 : ℤ) ∣ n ^ 16 - n ^ 12 := by
  have h : ∀ m : ZMod 240, m ^ 16 - m ^ 12 = 0 := by decide
  have hz : ((n ^ 16 - n ^ 12 : ℤ) : ZMod 240) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 16 - n ^ 12) 240).mp hz
  exact_mod_cast hdvd
