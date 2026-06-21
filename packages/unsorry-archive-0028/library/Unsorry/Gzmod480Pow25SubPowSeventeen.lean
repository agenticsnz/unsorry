import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_480_pow_25_sub_pow_seventeen (n : ℤ) : (480 : ℤ) ∣ n ^ 25 - n ^ 17 := by
  have h : ∀ m : ZMod 480, m ^ 25 - m ^ 17 = 0 := by decide
  have hz : ((n ^ 25 - n ^ 17 : ℤ) : ZMod 480) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 25 - n ^ 17) 480).mp hz
  exact_mod_cast hdvd
