import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_24_pow_62_sub_pow_28 (n : ℤ) : (24 : ℤ) ∣ n ^ 62 - n ^ 28 := by
  have h : ∀ m : ZMod 24, m ^ 62 - m ^ 28 = 0 := by decide
  have hz : ((n ^ 62 - n ^ 28 : ℤ) : ZMod 24) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 62 - n ^ 28) 24).mp hz
  exact_mod_cast hdvd
