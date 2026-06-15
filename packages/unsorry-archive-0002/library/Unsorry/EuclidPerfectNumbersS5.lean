import Mathlib.Tactic.NormNum.Prime

theorem mersenne_prime_one_le_exp (p : ℕ) (hp : Nat.Prime (2 ^ p - 1)) : 1 ≤ p := by
  cases p with
  | zero => norm_num at hp
  | succ n => exact Nat.succ_pos n
