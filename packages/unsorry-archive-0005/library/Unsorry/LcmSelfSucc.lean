import Mathlib

/-- Goal `lcm-self-succ`: `lcm n (n+1) = n·(n+1)`, since consecutive naturals are
coprime. See `library/index/`. -/
theorem lcm_self_succ (n : ℕ) : Nat.lcm n (n + 1) = n * (n + 1) := by
  have h : Nat.Coprime n (n + 1) := by simp [Nat.coprime_self_add_right]
  exact h.lcm_eq_mul
