import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_42_pow_seven_sub_pow_one (n : ℤ) : (42 : ℤ) ∣ n ^ 7 - n ^ 1 := by
  have h : ∀ m : ZMod 42, m ^ 7 - m ^ 1 = 0 := by decide
  have hz : ((n ^ 7 - n ^ 1 : ℤ) : ZMod 42) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 7 - n ^ 1) 42).mp hz
  exact_mod_cast hdvd
