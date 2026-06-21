import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_132_pow_52_sub_pow_two (n : ℤ) : (132 : ℤ) ∣ n ^ 52 - n ^ 2 := by
  have h : ∀ m : ZMod 132, m ^ 52 - m ^ 2 = 0 := by decide
  have hz : ((n ^ 52 - n ^ 2 : ℤ) : ZMod 132) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 52 - n ^ 2) 132).mp hz
  exact_mod_cast hdvd
