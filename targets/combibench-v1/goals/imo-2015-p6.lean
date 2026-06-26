import Mathlib

theorem imo_2015_p6 (a : ℕ+ → ℤ) (ha1 : ∀ j : ℕ+, 1 ≤ a j ∧ a j ≤ 2015)
    (ha2 : ∀ k l, k < l → k + a k ≠ l + a l) :
    ∃ b N : ℕ+, ∀ m n, n > m ∧ m ≥ N → |(∑ j ∈ Finset.Icc (m + 1) n, (a j - b))| ≤ 1007^2 := by
  sorry
