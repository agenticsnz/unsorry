import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_240_pow_21_sub_pow_seventeen (n : ℤ) : (240 : ℤ) ∣ n ^ 21 - n ^ 17 := by
  have h : ∀ m : ZMod 240, m ^ 21 - m ^ 17 = 0 := by decide
  have hz : ((n ^ 21 - n ^ 17 : ℤ) : ZMod 240) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 21 - n ^ 17) 240).mp hz
  exact_mod_cast hdvd
