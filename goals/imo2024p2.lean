import Mathlib

def answer : Set (ℕ × ℕ) := sorry

theorem imo2024p2 : {(a, b) | 0 < a ∧ 0 < b ∧ ∃ g N : ℕ, 0 < g ∧ 0 < N ∧ ∀ n : ℕ, N ≤ n →
    Nat.gcd (a ^ n + b) (b ^ n + a) = g} = answer := by
  sorry
