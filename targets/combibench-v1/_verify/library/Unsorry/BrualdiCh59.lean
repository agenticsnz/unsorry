import Mathlib.Data.Nat.Choose.Sum
import Mathlib.Tactic.Ring
import Mathlib.Tactic.NormNum

/-!
# Brualdi, Chapter 5, Exercise 9

We evaluate `∑_{k=0}^{n} (-1)^k * C(n,k) * 10^k = (-9)^n`.

Proof idea: by the binomial theorem, `(x + y)^n = ∑ x^k * y^(n-k) * C(n,k)`.
Taking `x = -10` and `y = 1` gives `(-9)^n = ∑ (-10)^k * C(n,k)`, and
`(-10)^k = (-1)^k * 10^k` matches the summands termwise.
-/

theorem brualdi_ch5_9 (n : ℕ) : ∑ k ∈ Finset.range (n + 1), (-1 : ℤ) ^ k * (n.choose k) * 10 ^ k =
    ((fun n => (-9 : ℤ)^n) : ℕ → ℤ ) n := by
  have h := add_pow (-10 : ℤ) 1 n
  have h9 : (-10 : ℤ) + 1 = -9 := by norm_num
  rw [h9] at h
  show _ = (-9 : ℤ) ^ n
  rw [h]
  refine Finset.sum_congr rfl fun k _ => ?_
  rw [one_pow, mul_one, show (-10 : ℤ) = -1 * 10 by norm_num, mul_pow]
  ring
