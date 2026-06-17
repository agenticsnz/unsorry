import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_240_pow_ten_sub_pow_six (n : ℤ) : (240 : ℤ) ∣ n ^ 10 - n ^ 6 := by
  have h : ∀ m : ZMod 240, m ^ 10 - m ^ 6 = 0 := by decide
  have hz : ((n ^ 10 - n ^ 6 : ℤ) : ZMod 240) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 10 - n ^ 6) 240).mp hz
  exact_mod_cast hdvd
