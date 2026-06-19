import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-72-pow-eighteen-sub-pow-six`: `72 ∣ n^18 - n^6` over `ℤ`, by a finite `ZMod 72` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_72_pow_eighteen_sub_pow_six (n : ℤ) : (72 : ℤ) ∣ n ^ 18 - n ^ 6 := by
  have h : ∀ m : ZMod 72, m ^ 18 - m ^ 6 = 0 := by decide
  have hz : ((n ^ 18 - n ^ 6 : ℤ) : ZMod 72) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 18 - n ^ 6) 72).mp hz
  exact_mod_cast hdvd
