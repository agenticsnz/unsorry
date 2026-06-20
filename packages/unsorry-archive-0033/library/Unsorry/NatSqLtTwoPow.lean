import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.Ring

private theorem sq_lt_two_pow_step_from_five {n : ℕ} (hn : 5 ≤ n)
    (h : n ^ 2 < 2 ^ n) : (n + 1) ^ 2 < 2 ^ (n + 1) := by
  have hquad : (n + 1) ^ 2 ≤ 2 * n ^ 2 := by
    nlinarith [hn]
  have hpow : 2 * n ^ 2 < 2 * 2 ^ n := Nat.mul_lt_mul_of_pos_left h (by norm_num)
  calc
    (n + 1) ^ 2 ≤ 2 * n ^ 2 := hquad
    _ < 2 * 2 ^ n := hpow
    _ = 2 ^ (n + 1) := by rw [pow_succ]; ring

theorem sq_lt_two_pow_of_five_le {n : ℕ} (hn : 5 ≤ n) : n ^ 2 < 2 ^ n := by
  obtain ⟨k, rfl⟩ := Nat.exists_eq_add_of_le hn
  suffices h : ∀ k : ℕ, (5 + k) ^ 2 < 2 ^ (5 + k) by exact h k
  intro k
  induction k with
  | zero => norm_num
  | succ k ih =>
      simpa [Nat.add_assoc] using sq_lt_two_pow_step_from_five (n := 5 + k) (by omega) ih
