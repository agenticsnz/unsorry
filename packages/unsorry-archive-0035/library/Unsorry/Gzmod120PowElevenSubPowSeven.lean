import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-120-pow-eleven-sub-pow-seven`: `120 ∣ n^11 - n^7` over `ℤ`, by a finite `ZMod 120` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_120_pow_eleven_sub_pow_seven (n : ℤ) : (120 : ℤ) ∣ n ^ 11 - n ^ 7 := by
  have h : ∀ m : ZMod 120, m ^ 11 - m ^ 7 = 0 := by decide
  have hz : ((n ^ 11 - n ^ 7 : ℤ) : ZMod 120) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 11 - n ^ 7) 120).mp hz
  exact_mod_cast hdvd
