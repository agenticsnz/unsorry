import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_264_pow_27_sub_pow_seventeen (n : ℤ) : (264 : ℤ) ∣ n ^ 27 - n ^ 17 := by
  have h : ∀ m : ZMod 264, m ^ 27 - m ^ 17 = 0 := by decide
  have hz : ((n ^ 27 - n ^ 17 : ℤ) : ZMod 264) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 27 - n ^ 17) 264).mp hz
  exact_mod_cast hdvd
