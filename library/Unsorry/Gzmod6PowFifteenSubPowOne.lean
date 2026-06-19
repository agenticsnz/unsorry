import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_6_pow_fifteen_sub_pow_one (n : ℤ) : (6 : ℤ) ∣ n ^ 15 - n ^ 1 := by
  have h : ∀ m : ZMod 6, m ^ 15 - m ^ 1 = 0 := by decide
  have hz : ((n ^ 15 - n ^ 1 : ℤ) : ZMod 6) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 15 - n ^ 1) 6).mp hz
  exact_mod_cast hdvd
