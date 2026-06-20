import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-132-pow-thirteen-sub-pow-three`: `132 ∣ n^13 - n^3` over `ℤ`, by a finite `ZMod 132` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_132_pow_thirteen_sub_pow_three (n : ℤ) : (132 : ℤ) ∣ n ^ 13 - n ^ 3 := by
  have h : ∀ m : ZMod 132, m ^ 13 - m ^ 3 = 0 := by decide
  have hz : ((n ^ 13 - n ^ 3 : ℤ) : ZMod 132) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 13 - n ^ 3) 132).mp hz
  exact_mod_cast hdvd
