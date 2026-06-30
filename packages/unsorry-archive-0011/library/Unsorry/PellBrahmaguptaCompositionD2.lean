import Mathlib.Tactic.Ring
import Mathlib.Tactic.Linarith

/-!
# Brahmagupta composition for the Pell equation `x² - 2 y² = 1`

If `(a, b)` and `(c, e)` are both solutions of `x² - 2 y² = 1`, then their
Brahmagupta composition `(a c + 2 b e, a e + b c)` is again a solution. This is
an instance of the Brahmagupta–Fibonacci style identity
`(a² - 2 b²)(c² - 2 e²) = (a c + 2 b e)² - 2 (a e + b c)²`.
-/

theorem pell_brahmagupta_composition_d2 (a b c e : ℤ)
    (h1 : a ^ 2 - 2 * b ^ 2 = 1) (h2 : c ^ 2 - 2 * e ^ 2 = 1) :
    (a * c + 2 * b * e) ^ 2 - 2 * (a * e + b * c) ^ 2 = 1 := by
  have key : (a * c + 2 * b * e) ^ 2 - 2 * (a * e + b * c) ^ 2
      = (a ^ 2 - 2 * b ^ 2) * (c ^ 2 - 2 * e ^ 2) := by ring
  rw [key, h1, h2, mul_one]
