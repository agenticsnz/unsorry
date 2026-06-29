import Mathlib

def leftNeighbors {n : ℕ+} (people : Fin (2*n+1) → ZMod 2) (k : ℕ+) (i : Fin (2*n+1)) : Fin k → ZMod 2 :=
  fun j ↦ people <| (finRotate (2*n+1))^[j.1 + 1] i
def rightNeighbors {n : ℕ+} (people : Fin (2*n+1) → ZMod 2) (k : ℕ+) (i : Fin (2*n+1)) : Fin k → ZMod 2 :=
  fun j ↦ people <| (finRotate (2*n+1)).symm^[j.1 + 1] i

theorem imosl_2021_c5 (n k : ℕ+) (h : k < n) (people : Fin (2*n+1) → ZMod 2)
    (num_boys : (List.ofFn people).count 0 = n) (num_girls : (List.ofFn people).count 1 = n+1):
    ∃ (i : Fin (2*n+1)), people i = 1 ∧ ((List.ofFn (leftNeighbors people k i)).count 1 +
      (List.ofFn (rightNeighbors people k i)).count 1 >= k) := by
  sorry
