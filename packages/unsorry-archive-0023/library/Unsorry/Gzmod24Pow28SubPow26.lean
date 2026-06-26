import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_24_pow_28_sub_pow_26 (n : ℤ) : (24 : ℤ) ∣ n ^ 28 - n ^ 26 := by
  have h : ∀ m : ZMod 24, m ^ 28 - m ^ 26 = 0 := by decide
  have hz : ((n ^ 28 - n ^ 26 : ℤ) : ZMod 24) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 28 - n ^ 26) 24).mp hz
  exact_mod_cast hdvd
