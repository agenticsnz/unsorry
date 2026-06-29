import Mathlib.Data.Nat.GCD.Basic

/-- The product of two consecutive naturals is coprime to its own successor,
since any natural number is coprime to the next one. -/
theorem consec_prod_succ_coprime (n : ℕ) : Nat.Coprime (n * (n + 1)) (n * (n + 1) + 1) :=
  Nat.coprime_self_add_right.mpr (Nat.coprime_one_right _)
