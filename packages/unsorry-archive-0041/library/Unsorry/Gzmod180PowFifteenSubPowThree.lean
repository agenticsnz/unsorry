import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-180-pow-fifteen-sub-pow-three`: `180 ∣ n^15 - n^3` over `ℤ`, by a finite `ZMod 180` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_180_pow_fifteen_sub_pow_three (n : ℤ) : (180 : ℤ) ∣ n ^ 15 - n ^ 3 := by
  have h : ∀ m : ZMod 180, m ^ 15 - m ^ 3 = 0 := by decide
  have hz : ((n ^ 15 - n ^ 3 : ℤ) : ZMod 180) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 15 - n ^ 3) 180).mp hz
  exact_mod_cast hdvd
