import Mathlib

set_option maxRecDepth 8000 in
theorem dvd_120_pow_seven_sub_pow_three (n : ℤ) : (120 : ℤ) ∣ n ^ 7 - n ^ 3 := by
  have h : ∀ m : ZMod 120, m ^ 7 - m ^ 3 = 0 := by decide
  have hz : ((n ^ 7 - n ^ 3 : ℤ) : ZMod 120) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 7 - n ^ 3) 120).mp hz
  exact_mod_cast hdvd
