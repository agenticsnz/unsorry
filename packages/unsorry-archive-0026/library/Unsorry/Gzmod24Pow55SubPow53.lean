import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_24_pow_55_sub_pow_53 (n : ℤ) : (24 : ℤ) ∣ n ^ 55 - n ^ 53 := by
  have h : ∀ m : ZMod 24, m ^ 55 - m ^ 53 = 0 := by decide
  have hz : ((n ^ 55 - n ^ 53 : ℤ) : ZMod 24) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 55 - n ^ 53) 24).mp hz
  exact_mod_cast hdvd
