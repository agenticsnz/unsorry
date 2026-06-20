import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-132-pow-eighteen-sub-pow-eight`: `132 ∣ n^18 - n^8` over `ℤ`, by a finite `ZMod 132` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_132_pow_eighteen_sub_pow_eight (n : ℤ) : (132 : ℤ) ∣ n ^ 18 - n ^ 8 := by
  have h : ∀ m : ZMod 132, m ^ 18 - m ^ 8 = 0 := by decide
  have hz : ((n ^ 18 - n ^ 8 : ℤ) : ZMod 132) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 18 - n ^ 8) 132).mp hz
  exact_mod_cast hdvd
