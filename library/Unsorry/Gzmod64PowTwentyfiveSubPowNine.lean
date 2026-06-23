import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-64-pow-twentyfive-sub-pow-nine`: `64 ∣ n^25 - n^9` over `ℤ`, by a finite `ZMod 64` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_64_pow_twentyfive_sub_pow_nine (n : ℤ) : (64 : ℤ) ∣ n ^ 25 - n ^ 9 := by
  have h : ∀ m : ZMod 64, m ^ 25 - m ^ 9 = 0 := by decide
  have hz : ((n ^ 25 - n ^ 9 : ℤ) : ZMod 64) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 25 - n ^ 9) 64).mp hz
  exact_mod_cast hdvd
