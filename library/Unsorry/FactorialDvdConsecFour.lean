import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `factorial-dvd-consec-four`: `24 ∣` the product of 4 consecutive integers `n * (n + 1) * (n + 2) * (n + 3)`,
by a finite `ZMod 24` case check lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. -/
theorem factorial_dvd_consec_four (n : ℤ) : (24 : ℤ) ∣ n * (n + 1) * (n + 2) * (n + 3) := by
  have h : ∀ m : ZMod 24, m * (m + 1) * (m + 2) * (m + 3) = 0 := by decide
  have hz : ((n * (n + 1) * (n + 2) * (n + 3) : ℤ) : ZMod 24) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n * (n + 1) * (n + 2) * (n + 3)) 24).mp hz
  exact_mod_cast hdvd
