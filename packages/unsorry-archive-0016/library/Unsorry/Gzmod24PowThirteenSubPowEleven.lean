import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_24_pow_thirteen_sub_pow_eleven (n : ℤ) : (24 : ℤ) ∣ n ^ 13 - n ^ 11 := by
  have h : ∀ m : ZMod 24, m ^ 13 - m ^ 11 = 0 := by decide
  have hz : ((n ^ 13 - n ^ 11 : ℤ) : ZMod 24) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 13 - n ^ 11) 24).mp hz
  exact_mod_cast hdvd
