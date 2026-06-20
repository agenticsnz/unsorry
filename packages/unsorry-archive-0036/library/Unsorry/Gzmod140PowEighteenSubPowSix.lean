import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-140-pow-eighteen-sub-pow-six`: `140 ∣ n^18 - n^6` over `ℤ`, by a finite `ZMod 140` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_140_pow_eighteen_sub_pow_six (n : ℤ) : (140 : ℤ) ∣ n ^ 18 - n ^ 6 := by
  have h : ∀ m : ZMod 140, m ^ 18 - m ^ 6 = 0 := by decide
  have hz : ((n ^ 18 - n ^ 6 : ℤ) : ZMod 140) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 18 - n ^ 6) 140).mp hz
  exact_mod_cast hdvd
