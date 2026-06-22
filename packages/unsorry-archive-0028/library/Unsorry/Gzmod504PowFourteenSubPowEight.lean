import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_504_pow_fourteen_sub_pow_eight (n : ℤ) : (504 : ℤ) ∣ n ^ 14 - n ^ 8 := by
  have h : ∀ m : ZMod 504, m ^ 14 - m ^ 8 = 0 := by decide
  have hz : ((n ^ 14 - n ^ 8 : ℤ) : ZMod 504) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 14 - n ^ 8) 504).mp hz
  exact_mod_cast hdvd
