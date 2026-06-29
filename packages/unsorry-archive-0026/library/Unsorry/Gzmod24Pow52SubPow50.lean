import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_24_pow_52_sub_pow_50 (n : ℤ) : (24 : ℤ) ∣ n ^ 52 - n ^ 50 := by
  have h : ∀ m : ZMod 24, m ^ 52 - m ^ 50 = 0 := by decide
  have hz : ((n ^ 52 - n ^ 50 : ℤ) : ZMod 24) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 52 - n ^ 50) 24).mp hz
  exact_mod_cast hdvd
