import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-260-pow-eighteen-sub-pow-six`: `260 ∣ n^18 - n^6` over `ℤ`, by a finite `ZMod 260` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_260_pow_eighteen_sub_pow_six (n : ℤ) : (260 : ℤ) ∣ n ^ 18 - n ^ 6 := by
  have h : ∀ m : ZMod 260, m ^ 18 - m ^ 6 = 0 := by decide
  have hz : ((n ^ 18 - n ^ 6 : ℤ) : ZMod 260) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 18 - n ^ 6) 260).mp hz
  exact_mod_cast hdvd
