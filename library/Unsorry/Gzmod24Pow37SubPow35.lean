import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_24_pow_37_sub_pow_35 (n : ℤ) : (24 : ℤ) ∣ n ^ 37 - n ^ 35 := by
  have h : ∀ m : ZMod 24, m ^ 37 - m ^ 35 = 0 := by decide
  have hz : ((n ^ 37 - n ^ 35 : ℤ) : ZMod 24) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 37 - n ^ 35) 24).mp hz
  exact_mod_cast hdvd
