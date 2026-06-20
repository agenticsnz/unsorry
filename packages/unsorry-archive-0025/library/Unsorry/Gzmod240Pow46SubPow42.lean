import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_240_pow_46_sub_pow_42 (n : ℤ) : (240 : ℤ) ∣ n ^ 46 - n ^ 42 := by
  have h : ∀ m : ZMod 240, m ^ 46 - m ^ 42 = 0 := by decide
  have hz : ((n ^ 46 - n ^ 42 : ℤ) : ZMod 240) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 46 - n ^ 42) 240).mp hz
  exact_mod_cast hdvd
