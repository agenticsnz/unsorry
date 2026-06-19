import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-48-pow-eleven-sub-pow-seven`: `48 ∣ n^11 - n^7` over `ℤ`, by a finite `ZMod 48` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_48_pow_eleven_sub_pow_seven (n : ℤ) : (48 : ℤ) ∣ n ^ 11 - n ^ 7 := by
  have h : ∀ m : ZMod 48, m ^ 11 - m ^ 7 = 0 := by decide
  have hz : ((n ^ 11 - n ^ 7 : ℤ) : ZMod 48) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 11 - n ^ 7) 48).mp hz
  exact_mod_cast hdvd
