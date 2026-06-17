import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_240_pow_thirteen_sub_pow_nine (n : ℤ) : (240 : ℤ) ∣ n ^ 13 - n ^ 9 := by
  have h : ∀ m : ZMod 240, m ^ 13 - m ^ 9 = 0 := by decide
  have hz : ((n ^ 13 - n ^ 9 : ℤ) : ZMod 240) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 13 - n ^ 9) 240).mp hz
  exact_mod_cast hdvd
