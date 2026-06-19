import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-72-pow-thirteen-sub-pow-seven`: `72 ∣ n^13 - n^7` over `ℤ`, by a finite `ZMod 72` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_72_pow_thirteen_sub_pow_seven (n : ℤ) : (72 : ℤ) ∣ n ^ 13 - n ^ 7 := by
  have h : ∀ m : ZMod 72, m ^ 13 - m ^ 7 = 0 := by decide
  have hz : ((n ^ 13 - n ^ 7 : ℤ) : ZMod 72) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 13 - n ^ 7) 72).mp hz
  exact_mod_cast hdvd
