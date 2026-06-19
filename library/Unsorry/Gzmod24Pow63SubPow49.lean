import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_24_pow_63_sub_pow_49 (n : ℤ) : (24 : ℤ) ∣ n ^ 63 - n ^ 49 := by
  have h : ∀ m : ZMod 24, m ^ 63 - m ^ 49 = 0 := by decide
  have hz : ((n ^ 63 - n ^ 49 : ℤ) : ZMod 24) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 63 - n ^ 49) 24).mp hz
  exact_mod_cast hdvd
