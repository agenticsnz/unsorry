import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_24_pow_60_sub_pow_22 (n : ℤ) : (24 : ℤ) ∣ n ^ 60 - n ^ 22 := by
  have h : ∀ m : ZMod 24, m ^ 60 - m ^ 22 = 0 := by decide
  have hz : ((n ^ 60 - n ^ 22 : ℤ) : ZMod 24) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 60 - n ^ 22) 24).mp hz
  exact_mod_cast hdvd
