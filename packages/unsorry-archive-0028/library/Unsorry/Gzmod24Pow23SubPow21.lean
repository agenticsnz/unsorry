import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_24_pow_23_sub_pow_21 (n : ℤ) : (24 : ℤ) ∣ n ^ 23 - n ^ 21 := by
  have h : ∀ m : ZMod 24, m ^ 23 - m ^ 21 = 0 := by decide
  have hz : ((n ^ 23 - n ^ 21 : ℤ) : ZMod 24) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 23 - n ^ 21) 24).mp hz
  exact_mod_cast hdvd
