import Mathlib.Data.Finset.Insert
import Mathlib.Tactic.IntervalCases

/-- The cube of any natural number is congruent modulo 37 to one of the
thirteen cubic residues. -/
theorem cube_mod_thirtyseven_mem (n : ℕ) :
    n ^ 3 % 37 ∈ ({0, 1, 6, 8, 10, 11, 14, 23, 26, 27, 29, 31, 36} : Finset ℕ) := by
  rw [Nat.pow_mod]
  have h : n % 37 < 37 := Nat.mod_lt _ (by decide)
  interval_cases (n % 37) <;> decide
