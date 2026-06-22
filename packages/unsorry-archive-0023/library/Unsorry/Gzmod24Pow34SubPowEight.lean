import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_24_pow_34_sub_pow_eight (n : ℤ) : (24 : ℤ) ∣ n ^ 34 - n ^ 8 := by
  have h : ∀ m : ZMod 24, m ^ 34 - m ^ 8 = 0 := by decide
  have hz : ((n ^ 34 - n ^ 8 : ℤ) : ZMod 24) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 34 - n ^ 8) 24).mp hz
  exact_mod_cast hdvd
