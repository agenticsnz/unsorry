import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_480_pow_fourteen_sub_pow_six (n : ℤ) : (480 : ℤ) ∣ n ^ 14 - n ^ 6 := by
  have h : ∀ m : ZMod 480, m ^ 14 - m ^ 6 = 0 := by decide
  have hz : ((n ^ 14 - n ^ 6 : ℤ) : ZMod 480) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 14 - n ^ 6) 480).mp hz
  exact_mod_cast hdvd
