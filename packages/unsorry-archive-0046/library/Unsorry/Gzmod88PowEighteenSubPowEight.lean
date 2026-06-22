import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-88-pow-eighteen-sub-pow-eight`: `88 ∣ n^18 - n^8` over `ℤ`, by a finite `ZMod 88` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_88_pow_eighteen_sub_pow_eight (n : ℤ) : (88 : ℤ) ∣ n ^ 18 - n ^ 8 := by
  have h : ∀ m : ZMod 88, m ^ 18 - m ^ 8 = 0 := by decide
  have hz : ((n ^ 18 - n ^ 8 : ℤ) : ZMod 88) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 18 - n ^ 8) 88).mp hz
  exact_mod_cast hdvd
