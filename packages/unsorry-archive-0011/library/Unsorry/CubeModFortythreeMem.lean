import Mathlib.Tactic.IntervalCases
import Mathlib.Data.Finset.Insert

/-!
# Cubic residues modulo 43

The cube of any natural number, reduced modulo 43, lands in the set of cubic
residues `{0,1,2,4,8,11,16,21,22,27,32,35,39,41,42}`.

The proof reduces `n ^ 3 % 43` to `(n % 43) ^ 3 % 43` and then checks the
finitely many possibilities `0 ≤ n % 43 < 43`.
-/

theorem cube_mod_fortythree_mem (n : ℕ) :
    (n^3) % 43 ∈ ({0,1,2,4,8,11,16,21,22,27,32,35,39,41,42} : Finset ℕ) := by
  have h : n ^ 3 % 43 = (n % 43) ^ 3 % 43 := by rw [Nat.pow_mod]
  rw [h]
  have hlt : n % 43 < 43 := Nat.mod_lt _ (by norm_num)
  interval_cases (n % 43) <;> decide
