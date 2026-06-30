import Mathlib

set_option maxRecDepth 40000 in
theorem gbinom_poly_nmul2mulnp1mul2mulnm1 (n : ℤ) : (3 : ℤ) ∣ (n * (2 * n + 1) * (2 * n - 1)) := by
  have h : ∀ m : ZMod 3, m * (2 * m + 1) * (2 * m - 1) = 0 := by decide
  have hz : ((n * (2 * n + 1) * (2 * n - 1) : ℤ) : ZMod 3) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n * (2 * n + 1) * (2 * n - 1)) 3).mp hz
  exact_mod_cast hdvd
