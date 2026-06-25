import Mathlib

open scoped Nat
def answer : Set (ℕ × ℕ × ℕ) := sorry

theorem imo2022p5 : {(a, b, p) | 0 < a ∧ 0 < b ∧ 0 < p ∧ Nat.Prime p ∧ a ^ p = b ! + p} = answer := by
  sorry
