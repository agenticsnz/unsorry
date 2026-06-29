import Mathlib

open Nat
def f {m : ℕ} (n : Finset.Icc 1 m → ℤ) (x : Equiv.Perm (Finset.Icc 1 m)) : ℤ := ∑ i, x i * n i

theorem imo_2001_p4 (m : ℕ) (h_m_pos: m > 1) (h_m_odd: Odd m) (n : Finset.Icc 1 m → ℤ):
    ∃ a b : Equiv.Perm (Finset.Icc 1 m), a ≠ b ∧ ↑(m !) ∣ (f n a - f n b) := by
  sorry
