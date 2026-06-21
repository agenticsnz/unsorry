import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_24_pow_eight_sub_pow_six (n : ℤ) : (24 : ℤ) ∣ n ^ 8 - n ^ 6 := by
  have h : ∀ m : ZMod 24, m ^ 8 - m ^ 6 = 0 := by decide
  have hz : ((n ^ 8 - n ^ 6 : ℤ) : ZMod 24) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 8 - n ^ 6) 24).mp hz
  exact_mod_cast hdvd
