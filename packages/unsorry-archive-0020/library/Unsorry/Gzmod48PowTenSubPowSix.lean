import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-48-pow-ten-sub-pow-six`: `48 ∣ n^10 - n^6` over `ℤ`, by a finite `ZMod 48` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_48_pow_ten_sub_pow_six (n : ℤ) : (48 : ℤ) ∣ n ^ 10 - n ^ 6 := by
  have h : ∀ m : ZMod 48, m ^ 10 - m ^ 6 = 0 := by decide
  have hz : ((n ^ 10 - n ^ 6 : ℤ) : ZMod 48) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 10 - n ^ 6) 48).mp hz
  exact_mod_cast hdvd
