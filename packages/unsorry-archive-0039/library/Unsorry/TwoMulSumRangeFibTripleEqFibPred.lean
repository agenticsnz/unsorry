import Mathlib
open Nat Finset
theorem two_mul_sum_range_fib_triple_eq_fib_pred (n : ℕ) : 2 * Finset.sum (Finset.range n) (fun i => Nat.fib (3 * i)) = Nat.fib (3 * n - 1) - 1 := by
  induction n with
  | zero => simp
  | succ k ih =>
    rw [Finset.sum_range_succ, Nat.mul_add, ih]
    rcases Nat.eq_zero_or_pos k with hk | hk
    · subst hk; decide
    · have h31 : 3 * k - 1 + 1 = 3 * k := by omega
      have hkey : Nat.fib (3 * (k+1) - 1) = Nat.fib (3*k - 1) + 2 * Nat.fib (3*k) := by
        have e1 : 3 * (k+1) - 1 = (3*k - 1) + 3 := by omega
        rw [e1]
        have a2 : (3*k - 1) + 3 = ((3*k-1)+1) + 2 := by omega
        have a1 : (3*k - 1) + 2 = ((3*k-1)+1) + 1 := by omega
        rw [a2, Nat.fib_add_two, a1, Nat.fib_add_two, h31]
        ring
      rw [hkey]
      have hpos : 1 ≤ Nat.fib (3*k - 1) := by
        have hle : 1 ≤ 3 * k - 1 := by omega
        calc 1 = Nat.fib 1 := by decide
          _ ≤ Nat.fib (3*k-1) := Nat.fib_mono hle
      omega