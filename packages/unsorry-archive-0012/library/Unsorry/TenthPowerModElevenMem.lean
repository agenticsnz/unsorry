import Mathlib

set_option maxRecDepth 8000 in
theorem tenth_power_mod_eleven_mem (n : ℕ) : n ^ 10 % 11 = 0 ∨ n ^ 10 % 11 = 1 := by
  rw [Nat.pow_mod]
  have h : n % 11 < 11 := Nat.mod_lt n (by norm_num)
  interval_cases (n % 11) <;> decide
