import Mathlib

structure peaceful_rooks (n : ℕ) : Type where
  carrier :  Matrix (Fin n) (Fin n) Bool
  is_peaceful_row : ∀ i, List.count true (List.ofFn (fun j => carrier i j)) = 1
  is_peaceful_col : ∀ j, List.count true (List.ofFn (fun i => carrier i j)) = 1
deriving Fintype

theorem imo_2014_p2 (n : ℕ) (hn : n ≥ 2) :
    IsGreatest {(k : ℕ) | (k > 0) ∧ ∀ r : peaceful_rooks n, ∃ i j : Fin n,
    i.val + k - 1 < n ∧ i.val + k - 1 < n ∧
    ∀ m n, m.val < k ∧ n.val < k → r.carrier (i + m) (j + n) = false}
    (((fun n => ⌈√n⌉₊ - 1) : ℕ → ℕ ) n) := by
  sorry
