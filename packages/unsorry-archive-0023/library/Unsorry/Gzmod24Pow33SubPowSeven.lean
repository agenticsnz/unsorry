import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_24_pow_33_sub_pow_seven (n : ℤ) : (24 : ℤ) ∣ n ^ 33 - n ^ 7 := by
  have h : ∀ m : ZMod 24, m ^ 33 - m ^ 7 = 0 := by decide
  have hz : ((n ^ 33 - n ^ 7 : ℤ) : ZMod 24) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 33 - n ^ 7) 24).mp hz
  exact_mod_cast hdvd
