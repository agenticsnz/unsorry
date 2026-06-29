import Mathlib

open Set Real Filter Topology Polynomial

theorem putnam_1978_b3 (P : ℕ+ → Polynomial ℝ)
(hP1 : P 1 = 1 + X)
(hP2 : P 2 = 1 + 2 * X)
(hPodd : ∀ n, P (2 * n + 1) = P (2 * n) + C ((n : ℝ) + 1) * X * P (2 * n - 1))
(hPeven : ∀ n, P (2 * n + 2) = P (2 * n + 1) + C ((n : ℝ) + 1) * X * P (2 * n))
(a : ℕ+ → ℝ)
(haroot : ∀ n, (P n).eval (a n) = 0)
(haub : ∀ n, ∀ x, (P n).eval x = 0 → x ≤ a n)
: (StrictMono a ∧ Tendsto a atTop (𝓝 0)) := by
  sorry
