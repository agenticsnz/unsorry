import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_24_pow_eleven_sub_pow_nine (n : ℤ) : (24 : ℤ) ∣ n ^ 11 - n ^ 9 := by
  have h : ∀ m : ZMod 24, m ^ 11 - m ^ 9 = 0 := by decide
  have hz : ((n ^ 11 - n ^ 9 : ℤ) : ZMod 24) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 11 - n ^ 9) 24).mp hz
  exact_mod_cast hdvd
