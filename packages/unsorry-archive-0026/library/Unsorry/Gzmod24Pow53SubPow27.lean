import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_24_pow_53_sub_pow_27 (n : ℤ) : (24 : ℤ) ∣ n ^ 53 - n ^ 27 := by
  have h : ∀ m : ZMod 24, m ^ 53 - m ^ 27 = 0 := by decide
  have hz : ((n ^ 53 - n ^ 27 : ℤ) : ZMod 24) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 53 - n ^ 27) 24).mp hz
  exact_mod_cast hdvd
