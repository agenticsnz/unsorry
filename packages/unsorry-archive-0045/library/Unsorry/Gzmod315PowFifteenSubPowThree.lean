import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-315-pow-fifteen-sub-pow-three`: `315 ∣ n^15 - n^3` over `ℤ`, by a finite `ZMod 315` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_315_pow_fifteen_sub_pow_three (n : ℤ) : (315 : ℤ) ∣ n ^ 15 - n ^ 3 := by
  have h : ∀ m : ZMod 315, m ^ 15 - m ^ 3 = 0 := by decide
  have hz : ((n ^ 15 - n ^ 3 : ℤ) : ZMod 315) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 15 - n ^ 3) 315).mp hz
  exact_mod_cast hdvd
