import Mathlib.Algebra.Ring.Parity
import Mathlib.Tactic.Ring

theorem six_dvd_mul_succ_mul_succ_succ (n : ℕ) :
    6 ∣ n * (n + 1) * (n + 2) := by
  induction n with
  | zero => decide
  | succ k ih =>
    obtain ⟨a, ha⟩ := ih
    obtain ⟨r, hr⟩ := Nat.two_dvd_mul_add_one (k + 1)
    have h2 : (k + 1) * (k + 2) = 2 * r := hr
    refine ⟨a + r, ?_⟩
    have expand : (k + 1) * (k + 1 + 1) * (k + 1 + 2)
        = k * (k + 1) * (k + 2) + 3 * ((k + 1) * (k + 2)) := by ring
    rw [expand, ha, h2]; ring
