import Mathlib

structure PascalIndex (n : ℕ) where
  (i : ℕ) (j : ℕ)
  (i_le_n : i ≤ n)
  (j_le_i : j < i)
def IsAntiPascal (n : ℕ) (values : PascalIndex n → ℤ) : Prop :=
  ∀ index : PascalIndex n,
    if h : index.i < n then
      values index =
        abs (
          values { i := index.i + 1, j := index.j, i_le_n := by omega, j_le_i := by linarith [index.j_le_i] } -
          - values { i := index.i + 1, j := index.j + 1, i_le_n := by omega, j_le_i := by linarith [index.j_le_i] }
        )
    else
      true

theorem imo_2018_p3 : ((false) : Bool ) = ∃ values, IsAntiPascal 2018 values ∧
    Finset.Icc (1 : ℤ) (∑ i ∈ Finset.Icc 1 2018, i) = {x | ∃ i, x = values i} := by
  sorry
