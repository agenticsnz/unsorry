import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_504_pow_eighteen_sub_pow_twelve (n : ℤ) : (504 : ℤ) ∣ n ^ 18 - n ^ 12 := by
  have h : ∀ m : ZMod 504, m ^ 18 - m ^ 12 = 0 := by decide
  have hz : ((n ^ 18 - n ^ 12 : ℤ) : ZMod 504) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 18 - n ^ 12) 504).mp hz
  exact_mod_cast hdvd
