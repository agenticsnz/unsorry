import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_24_pow_63_sub_pow_61 (n : ℤ) : (24 : ℤ) ∣ n ^ 63 - n ^ 61 := by
  have h : ∀ m : ZMod 24, m ^ 63 - m ^ 61 = 0 := by decide
  have hz : ((n ^ 63 - n ^ 61 : ℤ) : ZMod 24) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 63 - n ^ 61) 24).mp hz
  exact_mod_cast hdvd
