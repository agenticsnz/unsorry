import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_504_pow_nineteen_sub_pow_thirteen (n : ℤ) : (504 : ℤ) ∣ n ^ 19 - n ^ 13 := by
  have h : ∀ m : ZMod 504, m ^ 19 - m ^ 13 = 0 := by decide
  have hz : ((n ^ 19 - n ^ 13 : ℤ) : ZMod 504) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 19 - n ^ 13) 504).mp hz
  exact_mod_cast hdvd
