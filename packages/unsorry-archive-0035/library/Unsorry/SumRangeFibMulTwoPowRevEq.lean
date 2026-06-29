import Mathlib

theorem sum_range_fib_mul_two_pow_rev_eq (n : ℕ) : ∑ k ∈ Finset.range (n + 1), Nat.fib k * 2 ^ (n - k) + Nat.fib (n + 3) = 2 ^ (n + 1) := by
  induction n with
  | zero => decide
  | succ m ih =>
    rw [Finset.sum_range_succ]
    have hsplit : ∀ k ∈ Finset.range (m + 1), Nat.fib k * 2 ^ (m + 1 - k) = 2 * (Nat.fib k * 2 ^ (m - k)) := by
      intro k hk
      rw [Finset.mem_range] at hk
      have : m + 1 - k = (m - k) + 1 := by omega
      rw [this, pow_succ]
      ring
    rw [Finset.sum_congr rfl hsplit, ← Finset.mul_sum]
    -- fib (m+1+3) = fib(m+4); fib(m+3) recurrences
    have hf3 : Nat.fib (m + 3) = Nat.fib (m + 2) + Nat.fib (m + 1) := by
      have h := Nat.fib_add_two (n := m + 1)
      have e2 : m + 1 + 2 = m + 3 := by ring
      have e1 : m + 1 + 1 = m + 2 := by ring
      rw [e2, e1] at h; omega
    have hf4 : Nat.fib (m + 4) = Nat.fib (m + 3) + Nat.fib (m + 2) := by
      have h := Nat.fib_add_two (n := m + 2)
      have e2 : m + 2 + 2 = m + 4 := by ring
      have e1 : m + 2 + 1 = m + 3 := by ring
      rw [e2, e1] at h; omega
    -- key: fib(m+1) + fib(m+4) = 2 * fib(m+3)
    have key : Nat.fib (m + 1) + Nat.fib (m + 1 + 3) = 2 * Nat.fib (m + 3) := by
      have e : m + 1 + 3 = m + 4 := by ring
      rw [e, hf4, hf3]; omega
    set S := ∑ k ∈ Finset.range (m + 1), Nat.fib k * 2 ^ (m - k) with hS
    have hpow : (2 : ℕ) ^ (m + 1 + 1) = 2 * 2 ^ (m + 1) := by rw [pow_succ]; ring
    have hdb : 2 * S + 2 * Nat.fib (m + 3) = 2 * 2 ^ (m + 1) := by
      rw [← Nat.mul_add, ih]
    -- goal: 2 * S + Nat.fib (m+1) * 2^(m+1-(m+1)) + Nat.fib (m+1+3) = 2^(m+1+1)
    have hsub : m + 1 - (m + 1) = 0 := by omega
    rw [hsub, pow_zero, mul_one, hpow]
    omega