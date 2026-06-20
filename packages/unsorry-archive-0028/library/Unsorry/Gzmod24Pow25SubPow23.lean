import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_24_pow_25_sub_pow_23 (n : ℤ) : (24 : ℤ) ∣ n ^ 25 - n ^ 23 := by
  have h : ∀ m : ZMod 24, m ^ 25 - m ^ 23 = 0 := by decide
  have hz : ((n ^ 25 - n ^ 23 : ℤ) : ZMod 24) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 25 - n ^ 23) 24).mp hz
  exact_mod_cast hdvd
