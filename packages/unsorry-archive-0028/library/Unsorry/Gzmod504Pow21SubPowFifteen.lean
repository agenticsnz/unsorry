import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_504_pow_21_sub_pow_fifteen (n : ℤ) : (504 : ℤ) ∣ n ^ 21 - n ^ 15 := by
  have h : ∀ m : ZMod 504, m ^ 21 - m ^ 15 = 0 := by decide
  have hz : ((n ^ 21 - n ^ 15 : ℤ) : ZMod 504) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 21 - n ^ 15) 504).mp hz
  exact_mod_cast hdvd
