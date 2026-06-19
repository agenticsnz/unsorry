import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_24_pow_47_sub_pow_45 (n : ℤ) : (24 : ℤ) ∣ n ^ 47 - n ^ 45 := by
  have h : ∀ m : ZMod 24, m ^ 47 - m ^ 45 = 0 := by decide
  have hz : ((n ^ 47 - n ^ 45 : ℤ) : ZMod 24) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 47 - n ^ 45) 24).mp hz
  exact_mod_cast hdvd
