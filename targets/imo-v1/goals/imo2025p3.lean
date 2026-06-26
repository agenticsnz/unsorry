import Mathlib

def Bonza (f : ℕ+ → ℕ+) : Prop := ∀ a b : ℕ+, (f a : ℤ) ∣ (b ^ (a : ℕ) : ℤ) - (f b ^ (f a : ℕ) : ℤ)
def answer : ℝ := sorry

theorem imo2025p3 : IsLeast {c : ℝ | ∀ f : ℕ+ → ℕ+, Bonza f → ∀ n, f n ≤ c * n}
    answer := by
  sorry
