import Mathlib

set_option maxRecDepth 40000 in
theorem gbinom_falling_five_fact_dvd (n : ℤ) : (120 : ℤ) ∣ (n * (n - 1) * (n - 2) * (n - 3) * (n - 4)) := by
  have h : ∀ m : ZMod 120, m * (m - 1) * (m - 2) * (m - 3) * (m - 4) = 0 := by decide
  have hz : ((n * (n - 1) * (n - 2) * (n - 3) * (n - 4) : ℤ) : ZMod 120) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n * (n - 1) * (n - 2) * (n - 3) * (n - 4)) 120).mp hz
  exact_mod_cast hdvd
