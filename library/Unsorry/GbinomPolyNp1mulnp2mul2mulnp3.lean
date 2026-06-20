import Mathlib

set_option maxRecDepth 40000 in
theorem gbinom_poly_np1mulnp2mul2mulnp3 (n : ℤ) : (6 : ℤ) ∣ ((n + 1) * (n + 2) * (2 * n + 3)) := by
  have h : ∀ m : ZMod 6, (m + 1) * (m + 2) * (2 * m + 3) = 0 := by decide
  have hz : (((n + 1) * (n + 2) * (2 * n + 3) : ℤ) : ZMod 6) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd ((n + 1) * (n + 2) * (2 * n + 3)) 6).mp hz
  exact_mod_cast hdvd
