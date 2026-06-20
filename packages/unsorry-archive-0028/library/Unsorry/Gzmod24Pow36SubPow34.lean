import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_24_pow_36_sub_pow_34 (n : ℤ) : (24 : ℤ) ∣ n ^ 36 - n ^ 34 := by
  have h : ∀ m : ZMod 24, m ^ 36 - m ^ 34 = 0 := by decide
  have hz : ((n ^ 36 - n ^ 34 : ℤ) : ZMod 24) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 36 - n ^ 34) 24).mp hz
  exact_mod_cast hdvd
