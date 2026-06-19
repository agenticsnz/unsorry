import Mathlib

theorem gcd_n_add_six_dvd_six (n : ℕ) : Nat.gcd n (n + 6) ∣ 6 := by
  exact (Nat.dvd_add_right (Nat.gcd_dvd_left n (n + 6))).mp (Nat.gcd_dvd_right n (n + 6))
