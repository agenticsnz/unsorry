import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-120-pow-fifteen-sub-pow-three`: `120 ∣ n^15 - n^3` over `ℤ`, by a finite `ZMod 120` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_120_pow_fifteen_sub_pow_three (n : ℤ) : (120 : ℤ) ∣ n ^ 15 - n ^ 3 := by
  have h : ∀ m : ZMod 120, m ^ 15 - m ^ 3 = 0 := by decide
  have hz : ((n ^ 15 - n ^ 3 : ℤ) : ZMod 120) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 15 - n ^ 3) 120).mp hz
  exact_mod_cast hdvd
