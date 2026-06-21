import Mathlib

/-- Goal `alt-sum-range-two-k-add-one-eq-signed-n`: the alternating sum of the
odd numbers `∑_{k<n} (-1)^k (2k+1) = (-1)^(n+1) n`. Induction on `n`. See
`library/index/`. -/
theorem alt_sum_range_two_k_add_one_eq_signed_n (n : ℕ) :
    ∑ k ∈ Finset.range n, (-1 : ℤ) ^ k * (2 * (k : ℤ) + 1) = (-1) ^ (n + 1) * (n : ℤ) := by
  induction n with
  | zero => simp
  | succ m ih =>
    rw [Finset.sum_range_succ, ih]
    push_cast
    ring
