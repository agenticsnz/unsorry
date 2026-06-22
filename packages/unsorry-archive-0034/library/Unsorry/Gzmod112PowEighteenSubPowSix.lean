import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-112-pow-eighteen-sub-pow-six`: `112 ∣ n^18 - n^6` over `ℤ`, by a finite `ZMod 112` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_112_pow_eighteen_sub_pow_six (n : ℤ) : (112 : ℤ) ∣ n ^ 18 - n ^ 6 := by
  have h : ∀ m : ZMod 112, m ^ 18 - m ^ 6 = 0 := by decide
  have hz : ((n ^ 18 - n ^ 6 : ℤ) : ZMod 112) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 18 - n ^ 6) 112).mp hz
  exact_mod_cast hdvd
