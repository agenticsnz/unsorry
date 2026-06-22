import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_480_pow_eighteen_sub_pow_ten (n : ℤ) : (480 : ℤ) ∣ n ^ 18 - n ^ 10 := by
  have h : ∀ m : ZMod 480, m ^ 18 - m ^ 10 = 0 := by decide
  have hz : ((n ^ 18 - n ^ 10 : ℤ) : ZMod 480) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 18 - n ^ 10) 480).mp hz
  exact_mod_cast hdvd
