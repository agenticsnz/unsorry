import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-182-pow-twentytwo-sub-pow-ten`: `182 ∣ n^22 - n^10` over `ℤ`, by a finite `ZMod 182` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_182_pow_twentytwo_sub_pow_ten (n : ℤ) : (182 : ℤ) ∣ n ^ 22 - n ^ 10 := by
  have h : ∀ m : ZMod 182, m ^ 22 - m ^ 10 = 0 := by decide
  have hz : ((n ^ 22 - n ^ 10 : ℤ) : ZMod 182) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 22 - n ^ 10) 182).mp hz
  exact_mod_cast hdvd
