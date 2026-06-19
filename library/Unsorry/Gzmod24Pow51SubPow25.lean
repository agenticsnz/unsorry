import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_24_pow_51_sub_pow_25 (n : ℤ) : (24 : ℤ) ∣ n ^ 51 - n ^ 25 := by
  have h : ∀ m : ZMod 24, m ^ 51 - m ^ 25 = 0 := by decide
  have hz : ((n ^ 51 - n ^ 25 : ℤ) : ZMod 24) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 51 - n ^ 25) 24).mp hz
  exact_mod_cast hdvd
