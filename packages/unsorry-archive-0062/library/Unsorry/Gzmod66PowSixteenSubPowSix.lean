import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-66-pow-sixteen-sub-pow-six`: `66 ∣ n^16 - n^6` over `ℤ`, by a finite `ZMod 66` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_66_pow_sixteen_sub_pow_six (n : ℤ) : (66 : ℤ) ∣ n ^ 16 - n ^ 6 := by
  have h : ∀ m : ZMod 66, m ^ 16 - m ^ 6 = 0 := by decide
  have hz : ((n ^ 16 - n ^ 6 : ℤ) : ZMod 66) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 16 - n ^ 6) 66).mp hz
  exact_mod_cast hdvd
