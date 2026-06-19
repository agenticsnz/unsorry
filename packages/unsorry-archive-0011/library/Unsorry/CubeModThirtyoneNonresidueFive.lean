import Mathlib.Data.Nat.ModEq
import Mathlib.Tactic.IntervalCases

/-!
# Cubes modulo 31 non-residues

The cube of any natural number is congruent to one of `0, 1, 2, 4, 8, 16` modulo `31`.
This proof reduces the cube modulo `31` to the cube of the residue `n % 31` and then
checks each of the thirty-one residues.
-/

theorem cube_mod_thirtyone_nonresidue_five (n : ℕ) : n ^ 3 % 31 ≠ 3 ∧ n ^ 3 % 31 ≠ 5 ∧ n ^ 3 % 31 ≠ 6 ∧ n ^ 3 % 31 ≠ 7 := by
  have hlt : n % 31 < 31 := Nat.mod_lt _ (by norm_num)
  have key : n ^ 3 % 31 = (n % 31) ^ 3 % 31 := ((Nat.mod_modEq n 31).pow 3).symm
  rw [key]
  interval_cases (n % 31) <;> decide