import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_504_pow_thirteen_sub_pow_seven (n : ℤ) : (504 : ℤ) ∣ n ^ 13 - n ^ 7 := by
  have h : ∀ m : ZMod 504, m ^ 13 - m ^ 7 = 0 := by decide
  have hz : ((n ^ 13 - n ^ 7 : ℤ) : ZMod 504) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 13 - n ^ 7) 504).mp hz
  exact_mod_cast hdvd
