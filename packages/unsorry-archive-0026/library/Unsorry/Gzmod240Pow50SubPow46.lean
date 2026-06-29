import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_240_pow_50_sub_pow_46 (n : ℤ) : (240 : ℤ) ∣ n ^ 50 - n ^ 46 := by
  have h : ∀ m : ZMod 240, m ^ 50 - m ^ 46 = 0 := by decide
  have hz : ((n ^ 50 - n ^ 46 : ℤ) : ZMod 240) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 50 - n ^ 46) 240).mp hz
  exact_mod_cast hdvd
