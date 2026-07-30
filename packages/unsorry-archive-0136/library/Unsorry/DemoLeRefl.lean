import Mathlib.Data.Nat.Notation

/-- `n ≤ n` for every natural number, by reflexivity of `≤`. -/
theorem demo_le_refl (n : ℕ) : n ≤ n := Nat.le_refl n
