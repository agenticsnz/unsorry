import Mathlib

theorem gcd_self_add_dvd (n k : ℕ) : Nat.gcd n (n + k) ∣ k := by
  exact (Nat.dvd_add_right (Nat.gcd_dvd_left n (n + k))).mp (Nat.gcd_dvd_right n (n + k))
