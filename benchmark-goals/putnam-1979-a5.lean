import Mathlib

open Set

theorem putnam_1979_a5 (S : ℝ → ℕ → ℤ)
(hS : S = fun x : ℝ => fun n : ℕ => Int.floor (n*x))
(P : ℝ → Prop)
(hP : ∀ x, P x ↔ x^3 - 10*x^2 + 29*x - 25 = 0)
: ∃ α β : ℝ, α ≠ β ∧ P α ∧ P β ∧ ∀ n : ℕ, ∃ m : ℤ, m > n ∧ ∃ c d : ℕ, S α c = m ∧ S β d = m := by
  sorry
