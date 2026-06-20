import Mathlib

theorem sum_id_mul_triangular_closed_form (n : ℕ) : 24 * ∑ k ∈ Finset.range n, k * (k * (k + 1) / 2) = (n - 1) * n * (n + 1) * (3 * n - 2) := by
  induction n with
  | zero => simp
  | succ n ih =>
    rw [Finset.sum_range_succ, Nat.mul_add, ih]
    have hT : 2 * (n * (n + 1) / 2) = n * (n + 1) :=
      Nat.mul_div_cancel' (Nat.even_mul_succ_self n).two_dvd
    have key : 24 * (n * (n * (n + 1) / 2)) = 12 * n * (n * (n + 1)) := by
      calc 24 * (n * (n * (n + 1) / 2))
          = 12 * n * (2 * (n * (n + 1) / 2)) := by ring
        _ = 12 * n * (n * (n + 1)) := by rw [hT]
    rw [key]
    cases n with
    | zero => decide
    | succ m =>
      have a1 : m + 1 - 1 = m := by omega
      have a2 : 3 * (m + 1) - 2 = 3 * m + 1 := by omega
      have a3 : m + 1 + 1 - 1 = m + 1 := by omega
      have a4 : 3 * (m + 1 + 1) - 2 = 3 * m + 4 := by omega
      rw [a1, a2, a3, a4]
      ring
