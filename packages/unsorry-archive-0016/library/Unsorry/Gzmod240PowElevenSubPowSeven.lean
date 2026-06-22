import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_240_pow_eleven_sub_pow_seven (n : ℤ) : (240 : ℤ) ∣ n ^ 11 - n ^ 7 := by
  have h : ∀ m : ZMod 240, m ^ 11 - m ^ 7 = 0 := by decide
  have hz : ((n ^ 11 - n ^ 7 : ℤ) : ZMod 240) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 11 - n ^ 7) 240).mp hz
  exact_mod_cast hdvd
