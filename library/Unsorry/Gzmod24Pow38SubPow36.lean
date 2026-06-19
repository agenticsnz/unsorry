import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_24_pow_38_sub_pow_36 (n : ℤ) : (24 : ℤ) ∣ n ^ 38 - n ^ 36 := by
  have h : ∀ m : ZMod 24, m ^ 38 - m ^ 36 = 0 := by decide
  have hz : ((n ^ 38 - n ^ 36 : ℤ) : ZMod 24) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 38 - n ^ 36) 24).mp hz
  exact_mod_cast hdvd
