import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_504_pow_23_sub_pow_seventeen (n : ℤ) : (504 : ℤ) ∣ n ^ 23 - n ^ 17 := by
  have h : ∀ m : ZMod 504, m ^ 23 - m ^ 17 = 0 := by decide
  have hz : ((n ^ 23 - n ^ 17 : ℤ) : ZMod 504) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 23 - n ^ 17) 504).mp hz
  exact_mod_cast hdvd
