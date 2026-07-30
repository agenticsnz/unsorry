import Mathlib.Algebra.Group.Nat.Defs

/-- Addition of natural numbers is commutative. -/
theorem demo_add_comm (a b : ℕ) : a + b = b + a := Nat.add_comm a b
