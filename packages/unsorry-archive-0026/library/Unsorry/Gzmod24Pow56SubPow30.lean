import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_24_pow_56_sub_pow_30 (n : ℤ) : (24 : ℤ) ∣ n ^ 56 - n ^ 30 := by
  have h : ∀ m : ZMod 24, m ^ 56 - m ^ 30 = 0 := by decide
  have hz : ((n ^ 56 - n ^ 30 : ℤ) : ZMod 24) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 56 - n ^ 30) 24).mp hz
  exact_mod_cast hdvd
