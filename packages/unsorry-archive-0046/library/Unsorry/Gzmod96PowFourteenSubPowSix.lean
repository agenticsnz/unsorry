import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-96-pow-fourteen-sub-pow-six`: `96 ∣ n^14 - n^6` over `ℤ`, by a finite `ZMod 96` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_96_pow_fourteen_sub_pow_six (n : ℤ) : (96 : ℤ) ∣ n ^ 14 - n ^ 6 := by
  have h : ∀ m : ZMod 96, m ^ 14 - m ^ 6 = 0 := by decide
  have hz : ((n ^ 14 - n ^ 6 : ℤ) : ZMod 96) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 14 - n ^ 6) 96).mp hz
  exact_mod_cast hdvd
