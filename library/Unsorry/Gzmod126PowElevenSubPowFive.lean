import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-126-pow-eleven-sub-pow-five`: `126 ∣ n^11 - n^5` over `ℤ`, by a finite `ZMod 126` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_126_pow_eleven_sub_pow_five (n : ℤ) : (126 : ℤ) ∣ n ^ 11 - n ^ 5 := by
  have h : ∀ m : ZMod 126, m ^ 11 - m ^ 5 = 0 := by decide
  have hz : ((n ^ 11 - n ^ 5 : ℤ) : ZMod 126) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 11 - n ^ 5) 126).mp hz
  exact_mod_cast hdvd
