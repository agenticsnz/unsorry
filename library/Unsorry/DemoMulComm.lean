import Mathlib.Algebra.Group.Nat.Defs

/-- Multiplication of natural numbers is commutative. -/
theorem demo_mul_comm (a b : ℕ) : a * b = b * a := Nat.mul_comm a b
