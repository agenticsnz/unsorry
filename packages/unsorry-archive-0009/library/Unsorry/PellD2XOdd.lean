import Mathlib

theorem pell_d2_x_odd (x y : ℤ) (h : x ^ 2 - 2 * y ^ 2 = 1) : Odd x := by
  rcases Int.even_or_odd x with he | ho
  · exfalso
    obtain ⟨k, hk⟩ := he
    rw [hk] at h
    ring_nf at h
    omega
  · exact ho
