import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_504_pow_twelve_sub_pow_six (n : ℤ) : (504 : ℤ) ∣ n ^ 12 - n ^ 6 := by
  have h : ∀ m : ZMod 504, m ^ 12 - m ^ 6 = 0 := by decide
  have hz : ((n ^ 12 - n ^ 6 : ℤ) : ZMod 504) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 12 - n ^ 6) 504).mp hz
  exact_mod_cast hdvd
