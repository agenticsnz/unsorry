import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-140-pow-fifteen-sub-pow-three`: `140 ∣ n^15 - n^3` over `ℤ`, by a finite `ZMod 140` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_140_pow_fifteen_sub_pow_three (n : ℤ) : (140 : ℤ) ∣ n ^ 15 - n ^ 3 := by
  have h : ∀ m : ZMod 140, m ^ 15 - m ^ 3 = 0 := by decide
  have hz : ((n ^ 15 - n ^ 3 : ℤ) : ZMod 140) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 15 - n ^ 3) 140).mp hz
  exact_mod_cast hdvd
