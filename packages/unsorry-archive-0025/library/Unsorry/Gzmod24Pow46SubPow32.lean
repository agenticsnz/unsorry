import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_24_pow_46_sub_pow_32 (n : ℤ) : (24 : ℤ) ∣ n ^ 46 - n ^ 32 := by
  have h : ∀ m : ZMod 24, m ^ 46 - m ^ 32 = 0 := by decide
  have hz : ((n ^ 46 - n ^ 32 : ℤ) : ZMod 24) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 46 - n ^ 32) 24).mp hz
  exact_mod_cast hdvd
