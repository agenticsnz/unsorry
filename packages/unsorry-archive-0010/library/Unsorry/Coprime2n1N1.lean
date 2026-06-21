import Mathlib.Data.Nat.GCD.Basic

/-- For every natural number `n`, the numbers `2 * n + 1` and `n + 1` share no
common factor other than one: any common divisor `d` also divides
`2 * (n + 1)`, hence divides their difference `1`. -/
theorem coprime_2n1_n1 (n : ℕ) : Nat.Coprime (2 * n + 1) (n + 1) := by
  have e : 2 * n + 1 = n + (n + 1) := by omega
  rw [e, Nat.coprime_add_self_left, Nat.coprime_self_add_right]
  exact Nat.coprime_one_right n
