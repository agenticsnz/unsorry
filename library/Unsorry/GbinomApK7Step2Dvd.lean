import Mathlib

set_option maxRecDepth 40000 in
theorem gbinom_ap_k7_step2_dvd (n : ℤ) : (315 : ℤ) ∣ (n * (n + 2) * (n + 4) * (n + 6) * (n + 8) * (n + 10) * (n + 12)) := by
  have h : ∀ m : ZMod 315, m * (m + 2) * (m + 4) * (m + 6) * (m + 8) * (m + 10) * (m + 12) = 0 := by decide
  have hz : ((n * (n + 2) * (n + 4) * (n + 6) * (n + 8) * (n + 10) * (n + 12) : ℤ) : ZMod 315) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n * (n + 2) * (n + 4) * (n + 6) * (n + 8) * (n + 10) * (n + 12)) 315).mp hz
  exact_mod_cast hdvd
