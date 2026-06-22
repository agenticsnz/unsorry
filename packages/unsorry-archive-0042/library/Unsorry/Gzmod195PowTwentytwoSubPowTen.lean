import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-195-pow-twentytwo-sub-pow-ten`: `195 ∣ n^22 - n^10` over `ℤ`, by a finite `ZMod 195` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_195_pow_twentytwo_sub_pow_ten (n : ℤ) : (195 : ℤ) ∣ n ^ 22 - n ^ 10 := by
  have h : ∀ m : ZMod 195, m ^ 22 - m ^ 10 = 0 := by decide
  have hz : ((n ^ 22 - n ^ 10 : ℤ) : ZMod 195) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 22 - n ^ 10) 195).mp hz
  exact_mod_cast hdvd
