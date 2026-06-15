import Mathlib.Tactic.Ring
import Mathlib.Algebra.Order.Ring.Int

/-!
# Aurifeuillian quartic divisibility

The quadratic `a^2 + a + 1` divides the quartic `a^4 + a^2 + 1`, witnessed by the
factorisation `a^4 + a^2 + 1 = (a^2 + a + 1) * (a^2 - a + 1)`.
-/

theorem aurifeuillian_quartic_dvd (a : ℤ) : (a ^ 2 + a + 1) ∣ (a ^ 4 + a ^ 2 + 1) :=
  ⟨a ^ 2 - a + 1, by ring⟩
