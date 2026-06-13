import Mathlib.Data.Nat.Prime.Basic
import Mathlib.Tactic.Ring

theorem two_pow_pred_mersenne_arith (p : ℕ) (hp : 1 ≤ p) :
    (2 ^ (p - 1 + 1) - 1) * (2 ^ p - 1 + 1) = 2 * (2 ^ (p - 1) * (2 ^ p - 1)) := by
  obtain ⟨m, rfl⟩ : ∃ m, p = m + 1 := ⟨p - 1, by omega⟩
  have e1 : m + 1 - 1 + 1 = m + 1 := by omega
  have e2 : m + 1 - 1 = m := by omega
  rw [e1, e2, Nat.sub_add_cancel Nat.one_le_two_pow]
  generalize 2 ^ (m + 1) - 1 = b
  rw [pow_succ]
  ring
