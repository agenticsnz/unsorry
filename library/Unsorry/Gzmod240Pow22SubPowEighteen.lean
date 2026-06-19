import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_240_pow_22_sub_pow_eighteen (n : ℤ) : (240 : ℤ) ∣ n ^ 22 - n ^ 18 := by
  have h : ∀ m : ZMod 240, m ^ 22 - m ^ 18 = 0 := by decide
  have hz : ((n ^ 22 - n ^ 18 : ℤ) : ZMod 240) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 22 - n ^ 18) 240).mp hz
  exact_mod_cast hdvd
