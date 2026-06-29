import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_24_pow_58_sub_pow_56 (n : ℤ) : (24 : ℤ) ∣ n ^ 58 - n ^ 56 := by
  have h : ∀ m : ZMod 24, m ^ 58 - m ^ 56 = 0 := by decide
  have hz : ((n ^ 58 - n ^ 56 : ℤ) : ZMod 24) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 58 - n ^ 56) 24).mp hz
  exact_mod_cast hdvd
