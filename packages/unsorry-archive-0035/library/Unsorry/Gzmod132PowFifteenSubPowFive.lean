import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-132-pow-fifteen-sub-pow-five`: `132 ∣ n^15 - n^5` over `ℤ`, by a finite `ZMod 132` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_132_pow_fifteen_sub_pow_five (n : ℤ) : (132 : ℤ) ∣ n ^ 15 - n ^ 5 := by
  have h : ∀ m : ZMod 132, m ^ 15 - m ^ 5 = 0 := by decide
  have hz : ((n ^ 15 - n ^ 5 : ℤ) : ZMod 132) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 15 - n ^ 5) 132).mp hz
  exact_mod_cast hdvd
