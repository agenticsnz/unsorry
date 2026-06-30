import Mathlib

open Nat Topology Filter

theorem putnam_1967_a2 (S : ℕ → ℤ)
    (hS0 : S 0 = 1)
    (hSn : ∀ n ≥ 1, S n = {A : Matrix (Fin n) (Fin n) ℕ | (∀ i j, A i j = A j i) ∧ (∀ j, (∑ i, A i j) = 1)}.ncard) :
    (∀ n ≥ 1, S (n + 1) = S n + n * S (n - 1)) ∧
    (∀ x : ℝ, (∑' n : ℕ, S n * (x ^ n / (n)!)) = Real.exp (x + x ^ 2 / 2)) := by
  sorry
