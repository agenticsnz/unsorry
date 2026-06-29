import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_24_pow_fourteen_sub_pow_twelve (n : ℤ) : (24 : ℤ) ∣ n ^ 14 - n ^ 12 := by
  have h : ∀ m : ZMod 24, m ^ 14 - m ^ 12 = 0 := by decide
  have hz : ((n ^ 14 - n ^ 12 : ℤ) : ZMod 24) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 14 - n ^ 12) 24).mp hz
  exact_mod_cast hdvd
