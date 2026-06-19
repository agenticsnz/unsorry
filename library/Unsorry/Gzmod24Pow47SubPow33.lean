import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_24_pow_47_sub_pow_33 (n : ℤ) : (24 : ℤ) ∣ n ^ 47 - n ^ 33 := by
  have h : ∀ m : ZMod 24, m ^ 47 - m ^ 33 = 0 := by decide
  have hz : ((n ^ 47 - n ^ 33 : ℤ) : ZMod 24) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 47 - n ^ 33) 24).mp hz
  exact_mod_cast hdvd
