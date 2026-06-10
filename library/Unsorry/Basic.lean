import Mathlib.Algebra.Group.Basic

/-- Goal `nat-zero-lt-succ` (backlog: "Zero is strictly less than the successor
of any natural number"). Canonical statement `∀x₁∈ℕ:0<(x₁+1)`, content address
`4c71a8b47b7aafffade842e201fc8f16bd9580b8ea18aba97244599d6bfc0ad8` —
see `library/index/`. -/
theorem nat_zero_lt_succ : ∀ n : ℕ, 0 < n + 1 := fun n => Nat.succ_pos n
