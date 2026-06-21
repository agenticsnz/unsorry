import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-56-pow-fourteen-sub-pow-eight`: `56 ∣ n^14 - n^8` over `ℤ`, by a finite `ZMod 56` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_56_pow_fourteen_sub_pow_eight (n : ℤ) : (56 : ℤ) ∣ n ^ 14 - n ^ 8 := by
  have h : ∀ m : ZMod 56, m ^ 14 - m ^ 8 = 0 := by decide
  have hz : ((n ^ 14 - n ^ 8 : ℤ) : ZMod 56) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 14 - n ^ 8) 56).mp hz
  exact_mod_cast hdvd
