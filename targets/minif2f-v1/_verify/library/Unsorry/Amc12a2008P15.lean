import Mathlib.Algebra.BigOperators.Group.Finset.Defs
import Mathlib.Data.Real.Basic
import Mathlib.Topology.Defs.Induced

/-!
AMC 12A 2008 Problem 15: for `k = 2008 ^ 2 + 2 ^ 2008`, the units digit of
`k ^ 2 + 2 ^ k` is `6`.

Since `2008 ^ 2` ends in `4` and `2 ^ 2008 = 16 ^ 502` ends in `6`, the sum
`k` ends in `0`, so `k ^ 2` ends in `0`. Moreover `k = 4 * m + 4` with
`m = 1008015 + 2 ^ 2006`, and `2 ^ (4 * n + 4) = 16 ^ (n + 1)` always ends
in `6`, so `2 ^ k` ends in `6` and the total ends in `6`.

Every step is a congruence rewrite: the huge exponents only ever appear as
opaque subterms, never as literals the elaborator would have to evaluate.
-/

theorem amc12a_2008_p15 (k : ℕ) (h₀ : k = 2008 ^ 2 + 2 ^ 2008) :
    (k ^ 2 + 2 ^ k) % 10 = 6 := by
  -- Powers of sixteen always end in `6`.
  have h16 : ∀ m : ℕ, (16 : ℕ) ^ (m + 1) % 10 = 6 := by
    intro m
    induction m with
    | zero => rfl
    | succ n ih => rw [Nat.pow_succ, Nat.mul_mod, ih]
  have key : ∀ n : ℕ, (2 : ℕ) ^ (4 * n + 4) % 10 = 6 := by
    intro n
    rw [Nat.pow_add, Nat.pow_mul, show (2 : ℕ) ^ 4 = 16 from rfl, ← Nat.pow_succ]
    exact h16 n
  have h2008 : (2 : ℕ) ^ 2008 % 10 = 6 := by
    rw [show (2008 : ℕ) = 4 * 501 + 4 from rfl]
    exact key 501
  -- `k` ends in `0`, hence `k ^ 2` ends in `0`.
  have hk0 : k % 10 = 0 := by
    rw [h₀, Nat.add_mod, h2008]
    rfl
  have hsq : k ^ 2 % 10 = 0 := by
    rw [Nat.pow_mod, hk0]
  -- `k = 4 * (1008015 + 2 ^ 2006) + 4`, so `2 ^ k` ends in `6`.
  have h2p : (2 : ℕ) ^ 2008 = 4 * 2 ^ 2006 := by
    rw [show (2008 : ℕ) = 2 + 2006 from rfl, pow_add,
      show (2 : ℕ) ^ 2 = 4 from rfl]
  have hk4 : k = 4 * (1008015 + 2 ^ 2006) + 4 := by
    rw [h₀, Nat.mul_add, h2p, Nat.add_right_comm,
      show (4 : ℕ) * 1008015 + 4 = 2008 ^ 2 from rfl]
  have hpow : (2 : ℕ) ^ k % 10 = 6 := by
    rw [hk4]
    exact key (1008015 + 2 ^ 2006)
  rw [Nat.add_mod, hsq, hpow]
