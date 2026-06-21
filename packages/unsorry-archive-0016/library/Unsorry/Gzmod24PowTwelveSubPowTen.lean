import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_24_pow_twelve_sub_pow_ten (n : ℤ) : (24 : ℤ) ∣ n ^ 12 - n ^ 10 := by
  have h : ∀ m : ZMod 24, m ^ 12 - m ^ 10 = 0 := by decide
  have hz : ((n ^ 12 - n ^ 10 : ℤ) : ZMod 24) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 12 - n ^ 10) 24).mp hz
  exact_mod_cast hdvd
