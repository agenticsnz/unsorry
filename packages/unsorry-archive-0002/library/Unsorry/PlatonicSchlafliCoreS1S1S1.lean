import Mathlib.Algebra.Order.Field.Rat

/-!
# `nat_cast_le_rat_of_le` (goal `platonic-schlafli-core-s1-s1-s1`)

The canonical map `ℕ → ℚ` is monotone: `m ≤ n` implies `(m : ℚ) ≤ (n : ℚ)`.
This is the reverse direction of `Nat.cast_le`, which characterises `≤` on
casts of naturals into any ordered semiring; `ℚ` qualifies via its linear
ordered field structure.
-/

theorem nat_cast_le_rat_of_le (m n : ℕ) : m ≤ n → (m : ℚ) ≤ (n : ℚ) :=
  Nat.cast_le.mpr
