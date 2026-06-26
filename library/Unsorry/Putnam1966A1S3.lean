import Mathlib.Tactic.Ring

/-!
# Putnam 1966 A1 (square-difference identity)

The integer-division identity `(x + y) ^ 2 / 4 - (x - y) ^ 2 / 4 = x * y`.

Since `x + y` and `x - y` share the same parity, the two squares are congruent
modulo `4`, so the integer-division truncations differ by exactly the algebraic
quotient `((x + y) ^ 2 - (x - y) ^ 2) / 4 = x * y`.
-/

theorem putnam_1966_a1_quad_div (x y : ℤ) :
    (x + y) ^ 2 / 4 - (x - y) ^ 2 / 4 = x * y := by
  have h : (x + y) ^ 2 = (x - y) ^ 2 + 4 * (x * y) := by ring
  omega
