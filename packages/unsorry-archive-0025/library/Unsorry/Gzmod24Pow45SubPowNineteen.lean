import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_24_pow_45_sub_pow_nineteen (n : ℤ) : (24 : ℤ) ∣ n ^ 45 - n ^ 19 := by
  have h : ∀ m : ZMod 24, m ^ 45 - m ^ 19 = 0 := by decide
  have hz : ((n ^ 45 - n ^ 19 : ℤ) : ZMod 24) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 45 - n ^ 19) 24).mp hz
  exact_mod_cast hdvd
