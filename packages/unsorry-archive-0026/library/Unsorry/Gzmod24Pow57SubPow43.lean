import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_24_pow_57_sub_pow_43 (n : ℤ) : (24 : ℤ) ∣ n ^ 57 - n ^ 43 := by
  have h : ∀ m : ZMod 24, m ^ 57 - m ^ 43 = 0 := by decide
  have hz : ((n ^ 57 - n ^ 43 : ℤ) : ZMod 24) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 57 - n ^ 43) 24).mp hz
  exact_mod_cast hdvd
