import Mathlib.Data.Nat.ModEq
import Mathlib.Tactic.IntervalCases

/-!
# Cubes modulo 13

The cube of any natural number is congruent to one of `0, 1, 5, 8, 12` modulo `13`.
The proof reduces the cube modulo `13` to the cube of the residue `n % 13` and then
checks each of the thirteen residues.
-/

theorem cube_mod_thirteen_mem (n : ℕ) :
    n ^ 3 % 13 = 0 ∨ n ^ 3 % 13 = 1 ∨ n ^ 3 % 13 = 5 ∨ n ^ 3 % 13 = 8 ∨ n ^ 3 % 13 = 12 := by
  have hlt : n % 13 < 13 := Nat.mod_lt _ (by norm_num)
  have key : n ^ 3 % 13 = (n % 13) ^ 3 % 13 := ((Nat.mod_modEq n 13).pow 3).symm
  rw [key]
  interval_cases (n % 13) <;> decide
