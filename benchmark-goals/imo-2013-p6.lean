import Mathlib

open Equiv Fintype Finset
def IsBeautiful {n} (e : Perm (Fin (n + 1))) : Prop :=
  ∀ ⦃a b⦄, a < b → ∀ ⦃c⦄, b < c → ∀ ⦃d⦄, c < d → a.val + d.val = b.val + c.val →
    e a < e b ∧ e b < e d ∧ e a < e c ∧ e c < e d ∨
    e d < e b ∧ e b < e a ∧ e d < e c ∧ e c < e a ∨
    e b < e a ∧ e a < e c ∧ e b < e d ∧ e d < e c ∨
    e c < e a ∧ e a < e b ∧ e c < e d ∧ e d < e b ∨
    e a < e b ∧ e a < e c ∧ e d < e b ∧ e d < e c ∨
    e b < e a ∧ e c < e a ∧ e b < e d ∧ e c < e d
instance {n} : DecidablePred (IsBeautiful (n := n)) := by unfold IsBeautiful; infer_instance
def M (n : ℕ) : ℕ := #{e : Perm (Fin (n + 1)) | IsBeautiful e} / (n + 1)
def N (n : ℕ) : ℕ := #{xy ∈ .Icc 1 n ×ˢ .Icc 1 n | xy.1 + xy.2 ≤ n ∧ xy.1.gcd xy.2 = 1}

theorem imo_2013_p6 (n : ℕ) (hn : n ≥ 3) : M n = N n + 1 := by
  sorry
