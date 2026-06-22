import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_24_pow_44_sub_pow_ten (n : ℤ) : (24 : ℤ) ∣ n ^ 44 - n ^ 10 := by
  have h : ∀ m : ZMod 24, m ^ 44 - m ^ 10 = 0 := by decide
  have hz : ((n ^ 44 - n ^ 10 : ℤ) : ZMod 24) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 44 - n ^ 10) 24).mp hz
  exact_mod_cast hdvd
