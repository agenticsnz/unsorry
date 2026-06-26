import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `factorial-dvd-consec-three`: `6 ∣` the product of 3 consecutive integers `n * (n + 1) * (n + 2)`,
by a finite `ZMod 6` case check lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. -/
theorem factorial_dvd_consec_three (n : ℤ) : (6 : ℤ) ∣ n * (n + 1) * (n + 2) := by
  have h : ∀ m : ZMod 6, m * (m + 1) * (m + 2) = 0 := by decide
  have hz : ((n * (n + 1) * (n + 2) : ℤ) : ZMod 6) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n * (n + 1) * (n + 2)) 6).mp hz
  exact_mod_cast hdvd
